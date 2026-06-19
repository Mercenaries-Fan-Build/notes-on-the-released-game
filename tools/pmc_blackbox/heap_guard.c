/**
 * heap_guard.c — allocation-history tracker for the world-load heap corruption.
 *
 * The world-load crashes are heap-dependent: a different entity/component is the
 * victim every run (vtable 0xBDB410 entity, 0xBAA0A0 component, …), but the bad
 * pointers consistently land in the 0x1F0C…  region and the engine then vcalls
 * through garbage (FUN_007938C0, EIP=0 / wild). That signature = HEAP CORRUPTION
 * (one wild write or early free smashing whatever's nearby), not a deterministic
 * mislink — so chasing each victim's producer finds victims, not the culprit.
 *
 * The game's allocator is Havok's hkThreadMemory (FUN_0088cb70 alloc /
 * FUN_0088cbd0 free — see Memory/hkThreadMemory.cpp string @0x0088cc40): a
 * binned, thread-local pool, __thiscall, where free is passed (ptr, size) and
 * re-derives the bin. That rules out classic guard-byte redzones (inflating the
 * alloc size shifts the size->bin mapping and free would return the block to the
 * wrong free list, corrupting the allocator itself). So instead of MUTATING the
 * heap we OBSERVE it: detour alloc/free and record {op, ptr, size, caller} into a
 * lock-free ring. On a crash, HeapGuardQuery() scans the ring for the corrupted
 * address and reports what block covers it (and who allocated it), whether it was
 * freed after its last alloc (use-after-free), and the nearest preceding block
 * (overflow source). __builtin_return_address(0) in the detour IS the engine
 * caller of the allocator — i.e. the producer/freer we want to name.
 *
 * Safe by construction: the detour only does an InterlockedIncrement + 4 stores
 * (no allocation, no logging, no lock) so it can't recurse or deadlock on the hot
 * path; pmc_log runs only from HeapGuardQuery at crash time. Kill switch:
 * env PMC_NO_HEAP_GUARD=1, or build -DPMC_DISABLE_HEAP_GUARD.
 *
 * Addresses are HARDCODED for the cracked retail EXE (same basis as the other
 * pmc_bb hooks).
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#include "MinHook.h"

extern void pmc_log(const char *source, const char *fmt, ...);
extern void pmc_log_flush(void);

/* hkThreadMemory alloc/free (this=ECX, __thiscall). Verified from the decompile:
 *   FUN_0088cb70(this, int size, u32 flags)            -> block in EAX
 *   FUN_0088cbd0(this, void* ptr, int size, u32 flags) -> void                  */
#define VA_ALLOC 0x0088CB70u
#define VA_FREE  0x0088CBD0u

/* Ring buffer: 2^20 records * 16 B = 16 MB. One world-load does ~400k allocs, so
 * this holds a full load's history before wrapping. */
#define RING_BITS 20
#define RING_N    (1u << RING_BITS)
#define RING_MASK (RING_N - 1u)

typedef struct {
    DWORD ptr;       /* block address                                    */
    DWORD size;      /* requested size (free is passed the same size)    */
    DWORD caller;    /* engine return address = producer/freer           */
    DWORD meta;      /* (seq << 1) | op   (op: 0=alloc, 1=free)          */
} HgRec;

static HgRec        g_ring[RING_N];
static volatile LONG g_ringIdx = 0;
static volatile LONG g_enabled = 0;

typedef void *(__attribute__((thiscall)) *alloc_fn)(void *self, int size, unsigned flags);
typedef void  (__attribute__((thiscall)) *free_fn )(void *self, void *ptr, int size, unsigned flags);
static alloc_fn g_orig_alloc = NULL;
static free_fn  g_orig_free  = NULL;

static void hg_record(DWORD op, DWORD ptr, DWORD size, DWORD caller)
{
    LONG i = InterlockedIncrement(&g_ringIdx) - 1;
    HgRec *r = &g_ring[(DWORD)i & RING_MASK];
    r->ptr    = ptr;
    r->size   = size;
    r->caller = caller;
    r->meta   = ((DWORD)i << 1) | (op & 1u);
}

static void *__attribute__((thiscall)) Hook_Alloc(void *self, int size, unsigned flags)
{
    void *p = g_orig_alloc(self, size, flags);
    if (g_enabled && p)
        hg_record(0, (DWORD)p, (DWORD)size, (DWORD)__builtin_return_address(0));
    return p;
}

static void __attribute__((thiscall)) Hook_Free(void *self, void *ptr, int size, unsigned flags)
{
    if (g_enabled && ptr)
        hg_record(1, (DWORD)ptr, (DWORD)size, (DWORD)__builtin_return_address(0));
    g_orig_free(self, ptr, size, flags);
}

/* Crash-time forensics: scan the ring for records touching address T and report
 * the live block covering it, a use-after-free, and the nearest preceding block.
 * Called from the crash handler (single-threaded VEH context). */
void HeapGuardQuery(DWORD T)
{
    DWORD k;
    HgRec cover = {0}, freed = {0}, prev = {0};
    DWORD cover_seq = 0, free_seq = 0, prev_seq = 0, prev_gap = 0xFFFFFFFFu;
    int have_cover = 0, have_free = 0, have_prev = 0;

    if (!g_enabled || T < 0x00010000u)
        return;

    for (k = 0; k < RING_N; k++) {
        HgRec r = g_ring[k];
        DWORD seq, op, end;
        if (r.ptr == 0 && r.size == 0 && r.meta == 0)
            continue;                       /* never-written slot */
        seq = r.meta >> 1;
        op  = r.meta & 1u;
        end = r.ptr + r.size;               /* may wrap; size is small in practice */

        if (r.ptr <= T && T < end) {
            if (op == 0) {                  /* alloc covering T */
                if (!have_cover || seq > cover_seq) { cover = r; cover_seq = seq; have_cover = 1; }
            } else {                        /* free covering T */
                if (!have_free || seq > free_seq) { freed = r; free_seq = seq; have_free = 1; }
            }
        }
        if (op == 0 && end <= T && (T - end) < prev_gap) {
            prev_gap = T - end; prev = r; prev_seq = seq; have_prev = 1;
        }
    }

    pmc_log("heap", "  --- heap history for %08lX ---", T);
    if (have_cover)
        pmc_log("heap", "  COVER block=%08lX size=%lu caller=%08lX seq=%lu",
                cover.ptr, cover.size, cover.caller, cover_seq);
    else
        pmc_log("heap", "  COVER: no live alloc covers %08lX (freed/foreign?)", T);

    if (have_free && (!have_cover || free_seq > cover_seq))
        pmc_log("heap", "  *** USE-AFTER-FREE? block=%08lX size=%lu freed-by=%08lX seq=%lu "
                "(freed AFTER its last alloc) ***", freed.ptr, freed.size, freed.caller, free_seq);

    if (have_prev && prev_gap < 0x100)
        pmc_log("heap", "  PREV neighbor ends %lu B before T: block=%08lX size=%lu caller=%08lX "
                "(overflow source?)", prev_gap, prev.ptr, prev.size, prev.caller);
}

int InstallHeapGuard(void)
{
    MH_STATUS st;
    char buf[8];

    if (GetEnvironmentVariableA("PMC_NO_HEAP_GUARD", buf, sizeof(buf)) > 0) {
        pmc_log("heap", "heap-guard DISABLED via PMC_NO_HEAP_GUARD");
        pmc_log_flush();
        return 0;
    }

    st = MH_Initialize();   /* defensive — also init'd by the other hooks */
    if (st != MH_OK && st != MH_ERROR_ALREADY_INITIALIZED) {
        pmc_log("heap", "MH_Initialize failed: %s", MH_StatusToString(st));
        pmc_log_flush();
        return 0;
    }

    st = MH_CreateHook((LPVOID)VA_ALLOC, (LPVOID)Hook_Alloc, (LPVOID *)&g_orig_alloc);
    if (st != MH_OK) {
        pmc_log("heap", "MH_CreateHook(alloc 0x%08X) failed: %s", VA_ALLOC, MH_StatusToString(st));
        pmc_log_flush();
        return 0;
    }
    st = MH_CreateHook((LPVOID)VA_FREE, (LPVOID)Hook_Free, (LPVOID *)&g_orig_free);
    if (st != MH_OK) {
        pmc_log("heap", "MH_CreateHook(free 0x%08X) failed: %s", VA_FREE, MH_StatusToString(st));
        pmc_log_flush();
        return 0;
    }
    if (MH_EnableHook((LPVOID)VA_ALLOC) != MH_OK || MH_EnableHook((LPVOID)VA_FREE) != MH_OK) {
        pmc_log("heap", "MH_EnableHook(alloc/free) failed");
        pmc_log_flush();
        return 0;
    }

    g_enabled = 1;
    pmc_log("heap", "Heap-history tracker armed: alloc@0x%08X free@0x%08X, %u-record ring (%u MB). "
            "Source [heap]. On crash, HeapGuardQuery names the corruptor.",
            VA_ALLOC, VA_FREE, RING_N, (unsigned)(sizeof(g_ring) >> 20));
    pmc_log_flush();
    return 1;
}
