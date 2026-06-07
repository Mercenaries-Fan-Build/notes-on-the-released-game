/**
 * poolguard.asi — custom pool-allocator corruption tracer for Mercenaries 2: World in Flames
 *
 * Standalone diagnostic ASI (loaded by pmc_bb.dll / Ultimate ASI Loader from <game>/scripts/).
 *
 * The bug: during world-load a stray pointer is written ~4 bytes past some allocation, landing
 * on an adjacent FREE pool block's `next` link. When that block is later popped, the allocator
 * installs the garbage as the new free-list head and the next pop dereferences it -> AV at
 * 0x0084DD5B. Victim/value vary by boot but are deterministic within a boot.
 *
 * v7 detection (PURE DIAGNOSTIC — zero writes to game memory)
 * ----------------------------------------------------------
 * INSTALL-POP CATCH (primary, class-math-free). Both pool allocators pop by `head = block->next`.
 * Immediately after the allocator returns block B, B[0] STILL holds that `next` value (the owner
 * has not run yet). So on every pop we read B[0]: if it is non-zero and OUTSIDE the arena, then
 * B is the corrupted block P (its `next` link was overwritten while free) — caught at the exact
 * pop that installs the garbage head, one pop BEFORE the crash, with P's address known directly.
 * A one-shot sweep then finds P's real block size (the descriptor whose head == the garbage), and
 * an ADDRESS-KEYED hash (every allocation's ptr -> caller,size) names whoever allocated the block
 * physically below P — the OVERFLOWER.
 *
 * Backups: the 0x0084DD5B pop-fault VEH (unreadable-garbage that slips past the B[0] check), the
 * general wild-pointer AV VEH (PG_CATCHALL), and dispense-time validation (block returned below
 * 0x01000000 = garbage handed out directly, e.g. the 0x0042FFFF Pool2 case).
 *
 * v12 (load-step naming). Live debugging exonerated the converter counts (count1/count3) and the
 * AC20 wrapper (it delegates to the hooked DCE0+D760), and showed the crash is a stray STORE — a
 * record-hash u32 written one slot past a 16-byte block — driven by the 0x004Cxxxx world/mesh
 * loader. The single P-blksz "below P" probe wasn't enough (the overflower kept showing "not in
 * map" — evicted on hash collision, or not exactly adjacent). v12 adds a lock-free TEMPORAL RING
 * of every alloc and dumps, on any catch: (1) a full-map NEIGHBORHOOD SCAN that flags whichever
 * mapped block actually abuts/overlaps P, and (2) the recent alloc TIMELINE. The dominant client
 * caller VA in the timeline (expected in 0x004Cxxxx) is the load-step to breakpoint next boot,
 * then single-step to the offending store.
 *
 * Env: PG_RECORD=0 disables the hooks (VEH-only); PG_CATCHALL=0 disables the general AV dump.
 * Logging is write-through to poolguard.log (survives the hard crash) + mirrored to pmc_log.
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include "MinHook.h"

#define EXPECTED_EXE_SIZE   53482288
#define IMAGE_BASE          0x00400000
#define TEXT_START_VA       0x00401000
#define TEXT_SIZE           0x00703000
#define POOL_MIN_VALID      0x01000000

#define FAULT_VA            0x0084DD5B
#define DCE0_VA             0x0084DCE0      /* fast pool pop:  __fastcall(ECX=size)->EAX        */
#define POOL2_VA            0x0088CB70      /* small-obj pool: __thiscall(ECX=this,size,arg2)   */
#define D760_VA             0x0084D760      /* slow/large alloc: __stdcall(poolDesc,size,rounded) */
                                            /* pure stack args (no implicit EAX/ECX) — safe hook  */
                                            /* AC20 wrapper is NOT hookable: it reads EAX+ECX in.  */

#define POOL_DCE0           1
#define POOL_POOL2          2
#define POOL_D760           3

static int IsAllocFrame(DWORD v) {
    return (v >= 0x0084A000 && v < 0x0084E300)
        || (v >= 0x0088C800 && v < 0x0088CD00);
}

#define VA_TABLE_BASE_PTR   0x00DFD108
#define VA_ARENA_LO         0x00DFD114
#define VA_ARENA_HI         0x00DFD118
#define VA_NUM_CLASSES      0x00DFD124
#define DESC_STRIDE         0x18
#define DESC_HEAD_OFF       0x00
#define DESC_BLKSZ_OFF      0x08
#define DESC_USED_OFF       0x0C
#define DESC_FREE_OFF       0x10

#define RD32(va)            (*(volatile DWORD *)(DWORD_PTR)(va))

/* ------------------------------------------------------------------ *
 * Address-keyed allocation map (open addressing, last-writer-wins). Survives any flood
 * because it is keyed by block address, not a ring. ~3 MB BSS.
 * ------------------------------------------------------------------ */

#define AH_SLOTS  1048576           /* power of two (~12 MB); big enough to retain slow-path allocs */
#define AH_MASK   (AH_SLOTS - 1)
#define AH_PROBE  16

static volatile LONG g_ahPtr[AH_SLOTS];
static volatile LONG g_ahCaller[AH_SLOTS];
static volatile LONG g_ahSize[AH_SLOTS];

static DWORD AHashIndex(DWORD ptr) { return ((ptr >> 4) * 2654435761u) & AH_MASK; }

static void AHashPut(DWORD ptr, DWORD caller, DWORD size) {
    DWORD i = AHashIndex(ptr), n;
    for (n = 0; n < AH_PROBE; n++) {
        DWORD s = (i + n) & AH_MASK;
        DWORD cur = (DWORD)g_ahPtr[s];
        if (cur == 0 || cur == ptr) {
            g_ahPtr[s] = (LONG)ptr; g_ahCaller[s] = (LONG)caller; g_ahSize[s] = (LONG)size;
            return;
        }
    }
    g_ahPtr[i] = (LONG)ptr; g_ahCaller[i] = (LONG)caller; g_ahSize[i] = (LONG)size;
}

static int AHashGet(DWORD ptr, DWORD *caller, DWORD *size) {
    DWORD i = AHashIndex(ptr), n;
    for (n = 0; n < AH_PROBE; n++) {
        DWORD s = (i + n) & AH_MASK;
        if ((DWORD)g_ahPtr[s] == ptr) { *caller = (DWORD)g_ahCaller[s]; *size = (DWORD)g_ahSize[s]; return 1; }
        if (g_ahPtr[s] == 0) break;
    }
    return 0;
}

/* ------------------------------------------------------------------ *
 * Temporal ring (v12). The address-keyed map answers "who allocated THIS address" but loses the
 * ORDER of allocations and evicts on hash collision. The ring keeps the last RING_SLOTS allocs in
 * temporal order so the dump can print the load-step sequence right before the corruption — the
 * loop that allocates+fills blocks in sequence is the one that ran one element long. Lock-free:
 * a monotone ticket picks the slot; `seq` is stamped LAST so a reader seeing seq==t knows the row
 * is complete (torn rows are skipped). ~1.3 MB BSS.
 * ------------------------------------------------------------------ */

/* v17: 1<<20 slots (~20 MB BSS) spans the full ~450k-alloc world load with no wraparound, so a
 * victim block's ENTIRE alloc/free history survives to crash time (the UAF prior-owner lens below
 * needs the alloc that happened long before the corruption, which the old 64k ring evicted). */
#define RING_SLOTS  (1 << 20)        /* power of two */
#define RING_MASK   (RING_SLOTS - 1)

typedef struct { volatile LONG seq; DWORD ptr; DWORD size; DWORD caller; DWORD pool; } PgRing;
static PgRing        g_ring[RING_SLOTS];
static volatile LONG g_ringTicket = 0;

static void RingPut(DWORD pool, DWORD ptr, DWORD size, DWORD caller) {
    LONG t = InterlockedIncrement(&g_ringTicket);   /* 1-based, monotone */
    DWORD i = (DWORD)t & RING_MASK;
    g_ring[i].ptr = ptr; g_ring[i].size = size; g_ring[i].caller = caller; g_ring[i].pool = pool;
    g_ring[i].seq = t;                              /* publish last */
}

static void DumpVictimHistory(DWORD P);             /* v17: defined below; used by free-list scan */

/* ------------------------------------------------------------------ *
 * Globals.
 * ------------------------------------------------------------------ */

static HMODULE       g_hModule       = NULL;
static BOOL          g_exeVerified   = FALSE;
static BOOL          g_recordEnabled = TRUE;
static BOOL          g_catchAll      = TRUE;
static PVOID         g_veh           = NULL;
static volatile LONG g_dumped        = 0;
static volatile LONG g_dumpedGeneral = 0;

typedef void * (__fastcall *fn_DCE0)(unsigned int sizeHint);
typedef void * (__thiscall *fn_POOL2)(void *self, int size, int arg2);
typedef void * (__stdcall *fn_D760)(int poolDesc, int size, int rounded);
static fn_DCE0  g_origDCE0  = NULL;
static fn_POOL2 g_origPool2 = NULL;
static fn_D760  g_origD760  = NULL;

/* ------------------------------------------------------------------ *
 * Logging — own write-through file (survives a hard crash) + pmc_log mirror.
 * ------------------------------------------------------------------ */

#define PG_LOG_SOURCE "poolguard"
typedef void (*pfn_pmc_log)(const char *source, const char *fmt, ...);
static pfn_pmc_log g_pmc_log = NULL;
static HANDLE      g_ownLog  = INVALID_HANDLE_VALUE;

static void LogInit(void) {
    char path[MAX_PATH]; char *slash; HMODULE hBlackbox;
    GetModuleFileNameA(NULL, path, MAX_PATH);
    slash = strrchr(path, '\\');
    if (slash) strcpy(slash + 1, "poolguard.log"); else strcpy(path, "poolguard.log");
    g_ownLog = CreateFileA(path, GENERIC_WRITE, FILE_SHARE_READ, NULL,
                           CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_WRITE_THROUGH, NULL);
    hBlackbox = GetModuleHandleA("pmc_bb.dll");
    if (hBlackbox) g_pmc_log = (pfn_pmc_log)GetProcAddress(hBlackbox, "pmc_log");
}

static void Log(const char *fmt, ...) {
    char buf[1200]; va_list ap; int len;
    va_start(ap, fmt); len = wvsprintfA(buf, fmt, ap); va_end(ap);
    if (len <= 0) return;
    if (g_ownLog != INVALID_HANDLE_VALUE) {
        DWORD written; buf[len] = '\r'; buf[len + 1] = '\n';
        WriteFile(g_ownLog, buf, len + 2, &written, NULL);
        FlushFileBuffers(g_ownLog); buf[len] = '\0';
    }
    if (g_pmc_log) g_pmc_log(PG_LOG_SOURCE, "%s", buf);
}

static BOOL VerifyExeSize(void) {
    char path[MAX_PATH]; HANDLE h; DWORD size;
    GetModuleFileNameA(NULL, path, MAX_PATH);
    h = CreateFileA(path, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
    if (h == INVALID_HANDLE_VALUE) return FALSE;
    size = GetFileSize(h, NULL); CloseHandle(h);
    return (size == EXPECTED_EXE_SIZE);
}

/* ------------------------------------------------------------------ *
 * Helpers.
 * ------------------------------------------------------------------ */

static const char *PoolName(WORD pool) {
    switch (pool) {
        case POOL_DCE0:  return "FUN_0084DCE0";
        case POOL_POOL2: return "FUN_0088CB70";
        case POOL_D760:  return "FUN_0084D760";
    }
    return "?";
}

static DWORD ScanClientCaller(void *anchor) {
    DWORD *sp = (DWORD *)anchor; int i;
    for (i = 0; i < 96; i++) {
        DWORD v = sp[i];
        if (v >= TEXT_START_VA && v < (TEXT_START_VA + TEXT_SIZE) && !IsAllocFrame(v)) return v;
    }
    return 0;
}

static void HexDump(const char *label, DWORD addr, int bytes) {
    char line[200]; int off, n;
    if (addr == 0 || IsBadReadPtr((void *)(DWORD_PTR)addr, bytes)) {
        Log("  %s @0x%08lX: <unmapped>", label, (unsigned long)addr); return;
    }
    off = wsprintfA(line, "  %s @0x%08lX:", label, (unsigned long)addr);
    for (n = 0; n < bytes && off < (int)sizeof(line) - 12; n += 4)
        off += wsprintfA(line + off, " %08lX", (unsigned long)RD32(addr + n));
    Log("%s", line);
}

static const char *DescribeCaller(DWORD c, char *buf, int n) {
    DWORD cc, sz;
    if (c == 0) { lstrcpynA(buf, "(unknown)", n); return buf; }
    if (AHashGet(c, &cc, &sz)) { } /* not used; placeholder */
    wsprintfA(buf, "0x%08lX", (unsigned long)c);
    return buf;
}

/* ------------------------------------------------------------------ *
 * v12 dump helpers: temporal timeline + full-map neighborhood scan.
 * ------------------------------------------------------------------ */

/* Print the last `n` allocations in temporal order (oldest first). The dominant client caller VA
 * in this window — especially one in the 0x004Cxxxx world/mesh loader — is the load-step to set a
 * breakpoint on next boot, then single-step to the store that runs one element past its buffer. */
static void DumpRecentTimeline(int n) {
    LONG head = g_ringTicket, cnt = (head > n) ? n : head, j;
    Log("--- recent alloc timeline (last %ld of %ld allocs, oldest first) ---", (long)cnt, (long)head);
    for (j = cnt - 1; j >= 0; j--) {
        LONG seq = head - j; DWORD i = (DWORD)seq & RING_MASK;
        if (g_ring[i].seq != seq) continue;                 /* row overwritten since — skip */
        Log("  #%ld %-12s ptr=0x%08lX size=%lu caller=0x%08lX", (long)seq,
            PoolName((WORD)g_ring[i].pool), (unsigned long)g_ring[i].ptr,
            (unsigned long)g_ring[i].size, (unsigned long)g_ring[i].caller);
    }
}

/* Scan the WHOLE address map for allocations physically near P (not just P-blksz). Finds the real
 * overflower regardless of exact adjacency or where its hash slot landed; flags any block that
 * abuts or overlaps P. More robust than a single P-blksz probe (which misses stray stores and
 * different-size neighbors). One-shot, off the hot path. */
static void DumpNeighborhood(DWORD P, DWORD blksz) {
    DWORD winLo = P - 0x200, winHi = P + ((blksz ? blksz : 0x40) * 2), s;
    DWORD bestBase = 0, bestEnd = 0, bestSz = 0, bestCaller = 0;   /* closest mapped alloc ending <= P */
    int hits = 0;
    (void)blksz;
    /* v13: the overflower is often a LARGER buffer whose base sits below a tight ±64 window, so its
     * records overrun upward into the free block P. Two passes: (1) list mapped allocs in a wide
     * window for context, (2) full-map search for the alloc whose END is closest below P (within
     * 0x80) — that is the buffer that ran past its tail into P. Names its caller directly. */
    Log("--- neighborhood scan: window [0x%08lX,0x%08lX) + closest-below-P ---",
        (unsigned long)winLo, (unsigned long)winHi);
    for (s = 0; s < AH_SLOTS; s++) {
        DWORD q = (DWORD)g_ahPtr[s];
        DWORD qsz, qend, qc;
        if (!q) continue;
        qsz = (DWORD)g_ahSize[s]; qend = q + qsz; qc = (DWORD)g_ahCaller[s];
        if (qend <= P && (P - qend) < 0x80 && qend > bestEnd) {     /* ends just below P */
            bestEnd = qend; bestBase = q; bestSz = qsz; bestCaller = qc;
        }
        if (q >= winLo && q < winHi && q != P) {
            const char *flag = (q < P && qend > P) ? "  <== OVERLAPS P"
                             : (qend == P)         ? "  <== abuts P" : "";
            Log("  blk 0x%08lX reqSize=%lu end=0x%08lX caller=0x%08lX%s", (unsigned long)q,
                (unsigned long)qsz, (unsigned long)qend, (unsigned long)qc, flag);
            hits++;
        }
    }
    if (!hits) Log("  (no mapped allocs in window)");
    if (bestBase)
        Log(">>> OVERFLOWER (closest mapped alloc ending below P): blk=0x%08lX reqSize=%lu "
            "end=0x%08lX gap-to-P=%lu caller=0x%08lX  <== cross-ref this caller in Ghidra",
            (unsigned long)bestBase, (unsigned long)bestSz, (unsigned long)bestEnd,
            (unsigned long)(P - bestEnd), (unsigned long)bestCaller);
    else
        Log(">>> no mapped alloc ends within 0x80 below P — overflower untracked (freed/reused)");
}

/* v15: search the TEMPORAL RING (65536 deep, vs the address map which evicts on collision) for the
 * allocation that overran into P. Reports any alloc that CONTAINS P (a large source buffer P falls
 * inside) and the closest alloc ENDING below P within 64KB (a source whose tail overran upward).
 * This is what names the overflower when the map has evicted it. One-shot, off the hot path. */
static void DumpRingClosestBelow(DWORD P) {
    DWORD i;
    DWORD cPtr = 0, cSz = 0, cCaller = 0, cPool = 0;          /* alloc containing P */
    DWORD bEnd = 0, bPtr = 0, bSz = 0, bCaller = 0, bPool = 0; /* closest ending below P */
    for (i = 0; i < RING_SLOTS; i++) {
        DWORD q = g_ring[i].ptr, qsz, qend;
        if (!q || g_ring[i].seq == 0) continue;
        qsz = g_ring[i].size; qend = q + qsz;
        if (q <= P && qend > P && q > cPtr) {
            cPtr = q; cSz = qsz; cCaller = g_ring[i].caller; cPool = g_ring[i].pool;
        }
        if (qend <= P && (P - qend) < 0x10000 && qend > bEnd) {
            bEnd = qend; bPtr = q; bSz = qsz; bCaller = g_ring[i].caller; bPool = g_ring[i].pool;
        }
    }
    if (cPtr)
        Log("    ring: alloc CONTAINING P = 0x%08lX size=%lu end=0x%08lX caller=0x%08lX %s  <== OVERFLOWER?",
            (unsigned long)cPtr, (unsigned long)cSz, (unsigned long)(cPtr + cSz),
            (unsigned long)cCaller, PoolName((WORD)cPool));
    if (bPtr)
        Log("    ring: closest below P = 0x%08lX size=%lu end=0x%08lX gap=%lu caller=0x%08lX %s  <== OVERFLOWER?",
            (unsigned long)bPtr, (unsigned long)bSz, (unsigned long)bEnd,
            (unsigned long)(P - bEnd), (unsigned long)bCaller, PoolName((WORD)bPool));
    if (!cPtr && !bPtr) Log("    ring: no alloc within 64KB below/containing P (older than 65536 allocs)");
}

/* v14: proactive free-list integrity scan — works on ANY crash, not just the dd5b pop. On the
 * 0x4CC064 boots the corruption is already sitting in a free list (a block's `next` link was
 * overwritten) but the pop hasn't reached it yet, so the install-pop catch never fires. Walk every
 * size-class free list; the first node whose link points out of the arena means the PREVIOUS node
 * is the corrupted block P (P->next = garbage). Then run the overflower scan on P. Bounded + every
 * link validated in-arena before deref, so walking a bad chain can't fault. One-shot, crash-time. */
static void DumpFreeListScan(void) {
    DWORD lo = RD32(VA_ARENA_LO), hi = RD32(VA_ARENA_HI);
    DWORD tb = RD32(VA_TABLE_BASE_PTR), nc = RD32(VA_NUM_CLASSES), i;
    int found = 0;
    if (!lo || hi <= lo || !tb || !nc || nc > 4096) return;
    Log("--- free-list integrity scan (%lu classes, arena [0x%08lX,0x%08lX)) ---",
        (unsigned long)nc, (unsigned long)lo, (unsigned long)hi);
    for (i = 0; i < nc; i++) {
        DWORD d = tb + i * DESC_STRIDE;
        DWORD blksz = RD32(d + DESC_BLKSZ_OFF);
        DWORD node = RD32(d + DESC_HEAD_OFF), prev = 0;
        int steps;
        if (node && (node < lo || node >= hi)) {
            /* head itself is garbage — this is the dd5b case; the block that was popped is gone. */
            Log("class[%lu] blockSize=%lu: HEAD already garbage 0x%08lX (popped block lost)",
                (unsigned long)i, (unsigned long)blksz, (unsigned long)node);
            found++;
            continue;
        }
        for (steps = 0; node && steps < 200000; steps++) {
            DWORD next;
            if (IsBadReadPtr((void *)(DWORD_PTR)node, 4)) break;
            next = RD32(node);
            if (next != 0 && (next < lo || next >= hi)) {
                Log("class[%lu] blockSize=%lu CORRUPTED: P=0x%08lX  P->next=0x%08lX (out of arena)",
                    (unsigned long)i, (unsigned long)blksz, (unsigned long)node, (unsigned long)next);
                HexDump("P[0..16]", node, 16);
                DumpNeighborhood(node, blksz);
                DumpVictimHistory(node);          /* v17: prior-owner (UAF) lens */
                DumpRingClosestBelow(node);
                found++;
                break;
            }
            prev = node; (void)prev;
            node = next;
        }
    }
    if (!found) Log("  (no out-of-arena links found — corruption not yet in a free list)");
}

/* ------------------------------------------------------------------ *
 * The install-pop catch + dump.
 * ------------------------------------------------------------------ */

/* v17: UAF prior-owner lens. The overflower scan assumes an ADJACENT buffer overran into P. But
 * static review of all 27k functions found no count-driven {hash,0xF011157A,0} packer — the write
 * is a STRAY store through a DANGLING pointer (use-after-free): there is no adjacent overflower, so
 * that scan reports "untracked". The real culprit is whoever PREVIOUSLY owned P — allocated it,
 * kept the pointer, freed it, then wrote to it while free. The (now deep) ring holds P's full
 * allocation history in temporal order; the entry just before the current pop names that owner. */
static void DumpVictimHistory(DWORD P) {
    LONG head = g_ringTicket, n = (head < RING_SLOTS) ? head : RING_SLOTS, j;
    int shown = 0;
    Log("--- victim P=0x%08lX prior-owner history (UAF lens: who held the ptr after free) ---",
        (unsigned long)P);
    for (j = 0; j < n && shown < 12; j++) {            /* newest -> oldest */
        LONG t = head - j;
        DWORD i = (DWORD)t & RING_MASK;
        if (g_ring[i].seq != t || g_ring[i].ptr != P) continue;
        Log("  [#%ld %s] ptr=0x%08lX size=%lu caller=0x%08lX%s",
            (long)g_ring[i].seq, PoolName((WORD)g_ring[i].pool),
            (unsigned long)g_ring[i].ptr, (unsigned long)g_ring[i].size,
            (unsigned long)g_ring[i].caller,
            shown == 0 ? "  <- current pop (crash site)"
          : shown == 1 ? "  <<< PRIOR OWNER (UAF suspect: held ptr after free, wrote the texture record)"
          : "");
        shown++;
    }
    if (shown <= 1)
        Log("  (only the current pop in ring -> prior owner older than %d allocs OR a true adjacent "
            "overrun, not a UAF -- trust the overflower/neighborhood scan instead)", RING_SLOTS);
}

static void DumpInstallPop(DWORD P, DWORD pCaller, DWORD garbageNext, WORD pool) {
    DWORD lo = RD32(VA_ARENA_LO), hi = RD32(VA_ARENA_HI);
    DWORD tb = RD32(VA_TABLE_BASE_PTR), nc = RD32(VA_NUM_CLASSES);
    DWORD blksz = 0, descA = 0, k = 0, i;
    DWORD below = 0, ovrCaller = 0, ovrSize = 0, pOwnerCaller = 0, pOwnerSize = 0;

    Log("============== POOLGUARD: free-list link overwrite caught ==============");
    Log("pool=%s  CORRUPTED block P=0x%08lX  P->next(now head)=0x%08lX (out of arena)",
        PoolName(pool), (unsigned long)P, (unsigned long)garbageNext);
    Log("arena=[0x%08lX,0x%08lX)  P just dispensed to caller=0x%08lX",
        (unsigned long)lo, (unsigned long)hi, (unsigned long)pCaller);

    /* Find P's descriptor (the one whose head is now the garbage) to get the real block size. */
    if (tb && nc && nc <= 4096) {
        for (i = 0; i < nc; i++) {
            DWORD d = tb + i * DESC_STRIDE;
            if (RD32(d + DESC_HEAD_OFF) == garbageNext) {
                descA = d; k = i; blksz = RD32(d + DESC_BLKSZ_OFF); break;
            }
        }
    }
    if (descA)
        Log("descriptor[%lu]=0x%08lX blockSize=%lu used=%ld free=%ld",
            (unsigned long)k, (unsigned long)descA, (unsigned long)blksz,
            (long)RD32(descA + DESC_USED_OFF), (long)RD32(descA + DESC_FREE_OFF));
    else
        Log("descriptor not found by head match (head may have moved) — blockSize unknown");

    if (AHashGet(P, &pOwnerCaller, &pOwnerSize))
        Log("P allocation: reqSize=%lu caller=0x%08lX", (unsigned long)pOwnerSize, (unsigned long)pOwnerCaller);

    HexDump("P[0..16]", P, 16);

    /* OVERFLOWER = the block physically below P (wrote 4 bytes past its end into P->next). */
    if (blksz && blksz <= 0x4000) {
        below = P - blksz;
        Log("OVERFLOWER buffer = block below P @ P-0x%lX = 0x%08lX:",
            (unsigned long)blksz, (unsigned long)below);
        HexDump("below[0..32]", below, 32);
        HexDump("below[end-16]", P - 16, 16);
        if (AHashGet(below, &ovrCaller, &ovrSize))
            Log(">>> OVERFLOWER allocation: ptr=0x%08lX reqSize=%lu caller=0x%08lX  "
                "(THIS caller wrote one element past its buffer — cross-ref in Ghidra)",
                (unsigned long)below, (unsigned long)ovrSize, (unsigned long)ovrCaller);
        else
            Log(">>> OVERFLOWER allocation 0x%08lX not in alloc map (evicted, pre-hook, or a stray "
                "store rather than an adjacent overrun) — see neighborhood + timeline below",
                (unsigned long)below);
    }

    /* v12: don't trust the P-blksz assumption alone — scan the whole map for the real overflower,
     * then print the temporal load-step sequence to breakpoint next boot. */
    DumpNeighborhood(P, blksz);
    DumpVictimHistory(P);                 /* v17: name P's prior owner (UAF dangling-ptr holder) */
    DumpRecentTimeline(64);
    Log("========================================================================");
}

/* Hot path: after a pop returns B, B[0] still holds the just-installed `next`. If it is out of
 * arena, B is the corrupted block. One read + two compares per alloc. */
static void CheckInstallPop(DWORD B, DWORD caller, WORD pool) {
    DWORD lo, hi, next;
    if (g_dumped) return;
    lo = RD32(VA_ARENA_LO); hi = RD32(VA_ARENA_HI);
    if (!lo || hi <= lo) return;
    /* A `next` link only exists for free-list-managed blocks INSIDE the arena. Large/big-path
     * blocks (e.g. Pool2's >0x2000 route) live above the arena and their [0] is data, not a link
     * — guarding on B-in-arena avoids false-positiving those. */
    if (B < lo || B >= hi) return;
    if (IsBadReadPtr((void *)(DWORD_PTR)B, 4)) return;
    next = RD32(B);
    if (next == 0) return;
    if (next >= lo && next < hi) return;            /* a normal free-list link */
    if (InterlockedCompareExchange(&g_dumped, 1, 0) == 0)
        DumpInstallPop(B, caller, next, pool);
}

/* Dispense-time: a block returned below the arena floor is garbage handed out directly. */
static void CheckDispenseLow(WORD pool, DWORD ptr, DWORD size, DWORD caller) {
    if (ptr == 0 || ptr >= POOL_MIN_VALID) return;
    if (InterlockedCompareExchange(&g_dumped, 1, 0) == 0) {
        Log("============== POOLGUARD: garbage block dispensed ==============");
        Log("pool=%s garbage=0x%08lX reqSize=%lu receiver-caller=0x%08lX",
            PoolName(pool), (unsigned long)ptr, (unsigned long)size, (unsigned long)caller);
        HexDump("garbage", ptr, 16);
        Log("===============================================================");
    }
}

/* v16: deterministic-address CANARY. The corruption writes out-of-arena values to the SAME fixed
 * addresses every boot (verified across v14/v15). The crash-time ring shows the late crash site,
 * not the writer. So poll these canaries every 64 allocs; the instant one holds an out-of-arena
 * value, dump the loading thread's stack + the recent ring RIGHT THERE — within 64 allocs of the
 * actual texture-record write. That timeline names the writer instead of the downstream victim. */
static const DWORD g_canaries[] = { 0x1F0749B0, 0x1F0F4EC0, 0x1F0EB640, 0x1F035400, 0x1F101000 };
static volatile LONG g_canaryDumped = 0;
static volatile LONG g_allocTick    = 0;

static void DumpCanaryTrip(void *anchor, DWORD ca, DWORD val) {
    DWORD *sp = (DWORD *)anchor; int i, shown = 0;
    Log("############# POOLGUARD: CANARY TRIPPED — corruption just appeared #############");
    Log("canary 0x%08lX = 0x%08lX (out of arena) — dumping the WRITER's live context",
        (unsigned long)ca, (unsigned long)val);
    Log("    --- stack walk (loading thread .text return addresses) ---");
    if (!IsBadReadPtr(sp, 600 * 4))
        for (i = 0; i < 600 && shown < 40; i++) {
            DWORD v = sp[i];
            if (v >= TEXT_START_VA && v < (TEXT_START_VA + TEXT_SIZE)) {
                Log("    [+0x%03X] 0x%08lX%s", i * 4, (unsigned long)v, IsAllocFrame(v) ? " (alloc)" : "");
                shown++;
            }
        }
    DumpRecentTimeline(96);
    DumpFreeListScan();
    Log("###############################################################################");
}

static void CheckCanaries(void *anchor) {
    DWORD lo, hi; int k;
    if (g_canaryDumped) return;
    if ((InterlockedIncrement(&g_allocTick) & 0x3F) != 0) return;   /* every 64 allocs */
    lo = RD32(VA_ARENA_LO); hi = RD32(VA_ARENA_HI);
    if (!lo || hi <= lo) return;
    for (k = 0; k < (int)(sizeof(g_canaries) / sizeof(g_canaries[0])); k++) {
        DWORD ca = g_canaries[k], v;
        if (IsBadReadPtr((void *)(DWORD_PTR)ca, 4)) continue;       /* not committed yet */
        v = RD32(ca);
        if (v != 0 && (v < lo || v >= hi) &&
            InterlockedCompareExchange(&g_canaryDumped, 1, 0) == 0) {
            DumpCanaryTrip(anchor, ca, v);
            return;
        }
    }
}

static void * __fastcall Detour_DCE0(unsigned int sizeHint) {
    int anchor = 0;
    void *r = g_origDCE0(sizeHint);
    DWORD p = (DWORD)(DWORD_PTR)r;
    if (p && g_recordEnabled) {
        DWORD caller = ScanClientCaller(&anchor);
        AHashPut(p, caller, sizeHint);
        RingPut(POOL_DCE0, p, sizeHint, caller);
        CheckInstallPop(p, caller, POOL_DCE0);
        CheckDispenseLow(POOL_DCE0, p, sizeHint, caller);
        CheckCanaries(&anchor);
    }
    return r;
}

static void * __thiscall Detour_Pool2(void *self, int size, int arg2) {
    int anchor = 0;
    void *r = g_origPool2(self, size, arg2);
    DWORD p = (DWORD)(DWORD_PTR)r;
    if (p && g_recordEnabled) {
        DWORD caller = ScanClientCaller(&anchor);
        AHashPut(p, caller, (DWORD)size);
        RingPut(POOL_POOL2, p, (DWORD)size, caller);
        CheckInstallPop(p, caller, POOL_POOL2);
        CheckDispenseLow(POOL_POOL2, p, (DWORD)size, caller);
    }
    return r;
}

/* The slow/large allocator: blocks the fast pool couldn't serve come from here (the overflower
 * 0x1F035200 was one). Captures them into the address map so they can be named. No install-pop
 * check (slow blocks aren't free-list pops; the DCE0/Pool2 hooks cover those). */
static void * __stdcall Detour_D760(int poolDesc, int size, int rounded) {
    int anchor = 0;
    void *r = g_origD760(poolDesc, size, rounded);
    DWORD p = (DWORD)(DWORD_PTR)r;
    if (p && p >= POOL_MIN_VALID && g_recordEnabled) {
        DWORD caller = ScanClientCaller(&anchor);
        AHashPut(p, caller, (DWORD)size);
        RingPut(POOL_D760, p, (DWORD)size, caller);
    }
    return r;
}

/* ------------------------------------------------------------------ *
 * VEH backups.
 * ------------------------------------------------------------------ */

static void DumpPopFault(CONTEXT *ctx) {
    DWORD eax = ctx->Eax, esi = ctx->Esi;
    DWORD k = eax / DESC_STRIDE;
    DWORD tb = RD32(VA_TABLE_BASE_PTR), desc = tb + eax, blksz = 0;
    Log("============= POOLGUARD: pop fault (VEH backup) =============");
    Log("fault 0x%08lX EAX=0x%08lX ESI(garbage head)=0x%08lX class=%lu desc=0x%08lX",
        (unsigned long)ctx->Eip, (unsigned long)eax, (unsigned long)esi, (unsigned long)k,
        (unsigned long)desc);
    if (!IsBadReadPtr((void *)(DWORD_PTR)desc, DESC_STRIDE)) blksz = RD32(desc + DESC_BLKSZ_OFF);
    Log("blockSize=%lu  (install-pop catch did not fire — head was already garbage at first sight)",
        (unsigned long)blksz);
    DumpFreeListScan();
    DumpRecentTimeline(64);
    Log("============================================================");
}

/* Try to name a value as an allocation: exact match, else the nearest recorded alloc whose
 * [ptr, ptr+size) contains it (so a register pointing mid-object still resolves the base). */
static void NameValue(const char *what, DWORD v) {
    DWORD c, s;
    if (v < 0x10000000 || v >= 0x80000000) return;       /* not a heap-looking pointer */
    if (AHashGet(v, &c, &s)) {
        Log("    %s=0x%08lX -> ALLOC base reqSize=%lu caller=0x%08lX", what, (unsigned long)v,
            (unsigned long)s, (unsigned long)c);
    }
    HexDump(what, v, 32);
}

static void DumpGeneralAV(EXCEPTION_POINTERS *ep) {
    CONTEXT *c = ep->ContextRecord;
    DWORD acc = (DWORD)ep->ExceptionRecord->ExceptionInformation[1];
    int   wr  = (int)ep->ExceptionRecord->ExceptionInformation[0];
    DWORD *sp = (DWORD *)(DWORD_PTR)c->Esp; int i, shown = 0;
    DWORD cc, ss;
    Log("============= POOLGUARD: wild-pointer AV =============");
    Log("fault 0x%08lX %s 0x%08lX (unmapped)", (unsigned long)c->Eip, wr ? "WRITE->" : "READ<-",
        (unsigned long)acc);
    Log("EAX=%08lX EBX=%08lX ECX=%08lX EDX=%08lX ESI=%08lX EDI=%08lX EBP=%08lX ESP=%08lX",
        (unsigned long)c->Eax, (unsigned long)c->Ebx, (unsigned long)c->Ecx, (unsigned long)c->Edx,
        (unsigned long)c->Esi, (unsigned long)c->Edi, (unsigned long)c->Ebp, (unsigned long)c->Esp);
    if (AHashGet(acc, &cc, &ss))
        Log("    fault-addr 0x%08lX -> ALLOC base reqSize=%lu caller=0x%08lX", (unsigned long)acc,
            (unsigned long)ss, (unsigned long)cc);

    /* Resolve the pointer-bearing registers against the allocation map + dump their memory.
     * For the 0x4CC064 object-pool pop, the object base / table land here, naming the owner. */
    NameValue("EAX", c->Eax); NameValue("EBX", c->Ebx); NameValue("ECX", c->Ecx);
    NameValue("EDX", c->Edx); NameValue("ESI", c->Esi); NameValue("EDI", c->Edi);
    NameValue("EBP", c->Ebp);

    Log("    --- stack walk (game .text return addresses) ---");
    if (!IsBadReadPtr(sp, 256 * 4))
        for (i = 0; i < 256 && shown < 20; i++) {
            DWORD v = sp[i];
            if (v >= TEXT_START_VA && v < (TEXT_START_VA + TEXT_SIZE)) {
                Log("    [esp+0x%03X] 0x%08lX%s", i * 4, (unsigned long)v, IsAllocFrame(v) ? " (alloc)" : "");
                shown++;
            }
        }
    DumpFreeListScan();
    DumpRecentTimeline(64);
    Log("=====================================================");
}

static LONG CALLBACK PoolguardVeh(EXCEPTION_POINTERS *ep) {
    EXCEPTION_RECORD *er = ep->ExceptionRecord; DWORD fa;
    if (er->ExceptionCode != (DWORD)EXCEPTION_ACCESS_VIOLATION) return EXCEPTION_CONTINUE_SEARCH;
    fa = (DWORD)(DWORD_PTR)er->ExceptionAddress;
    if (fa == FAULT_VA) {
        if (InterlockedCompareExchange(&g_dumped, 1, 0) == 0) DumpPopFault(ep->ContextRecord);
        return EXCEPTION_CONTINUE_SEARCH;
    }
    if (g_catchAll && fa >= TEXT_START_VA && fa < (TEXT_START_VA + TEXT_SIZE)) {
        DWORD acc = (DWORD)er->ExceptionInformation[1];
        if (IsBadReadPtr((void *)(DWORD_PTR)acc, 1) &&
            InterlockedCompareExchange(&g_dumpedGeneral, 1, 0) == 0)
            DumpGeneralAV(ep);
    }
    return EXCEPTION_CONTINUE_SEARCH;
}

/* ------------------------------------------------------------------ *
 * Install.
 * ------------------------------------------------------------------ */

static int InstallOne(DWORD va, void *detour, void **orig, const char *name) {
    MH_STATUS st = MH_CreateHook((LPVOID)(DWORD_PTR)va, detour, orig);
    if (st != MH_OK) { Log("MH_CreateHook(%s) failed: %s", name, MH_StatusToString(st)); return 0; }
    st = MH_EnableHook((LPVOID)(DWORD_PTR)va);
    if (st != MH_OK) { Log("MH_EnableHook(%s) failed: %s", name, MH_StatusToString(st)); return 0; }
    Log("hook armed: %s @0x%08lX (trampoline 0x%08lX)", name, (unsigned long)va,
        (unsigned long)(DWORD)(DWORD_PTR)*orig);
    return 1;
}

static void InstallHooks(void) {
    int n = 0;
    MH_STATUS st = MH_Initialize();
    if (st != MH_OK && st != MH_ERROR_ALREADY_INITIALIZED) {
        Log("MH_Initialize failed: %s — VEH-only", MH_StatusToString(st)); return;
    }
    n += InstallOne(DCE0_VA,  (void *)Detour_DCE0,  (void **)&g_origDCE0,  "FUN_0084DCE0 (fast pool)");
    n += InstallOne(POOL2_VA, (void *)Detour_Pool2, (void **)&g_origPool2, "FUN_0088CB70 (small-obj pool)");
    n += InstallOne(D760_VA,  (void *)Detour_D760,  (void **)&g_origD760,  "FUN_0084D760 (slow alloc)");
    Log("%d/3 hooks armed (install-pop catch on pools + addr map incl. slow D760)", n);
}

static BOOL EnvDisabled(const char *name) {
    char v[8]; DWORD n = GetEnvironmentVariableA(name, v, sizeof(v));
    return (n == 1 && v[0] == '0');
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
    (void)lpvReserved;
    if (fdwReason == DLL_PROCESS_ATTACH) {
        g_hModule = (HMODULE)hinstDLL;
        DisableThreadLibraryCalls(hinstDLL);
        LogInit();
        g_exeVerified   = VerifyExeSize();
        g_recordEnabled = !EnvDisabled("PG_RECORD");
        g_catchAll      = !EnvDisabled("PG_CATCHALL");
        Log("============================================");
        Log("poolguard.asi loaded (PID %lu, exe_verified=%d, record=%d, catchall=%d) [v16]",
            (unsigned long)GetCurrentProcessId(), g_exeVerified, g_recordEnabled, g_catchAll);
        if (!g_exeVerified) {
            Log("REFUSING to install: EXE size != %d.", EXPECTED_EXE_SIZE);
            Log("============================================");
            return TRUE;
        }
        g_veh = AddVectoredExceptionHandler(1, PoolguardVeh);
        Log("VEH armed: pop-fault @0x%08X + %s wild-pointer AV", FAULT_VA, g_catchAll ? "general" : "(off)");
        if (g_recordEnabled) InstallHooks(); else Log("hooks disabled (PG_RECORD=0)");
        Log("============================================");
    } else if (fdwReason == DLL_PROCESS_DETACH) {
        if (g_veh) { RemoveVectoredExceptionHandler(g_veh); g_veh = NULL; }
        if (g_ownLog != INVALID_HANDLE_VALUE) { CloseHandle(g_ownLog); g_ownLog = INVALID_HANDLE_VALUE; }
    }
    return TRUE;
}
