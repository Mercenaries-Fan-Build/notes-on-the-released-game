/**
 * pool_probe.c — render-instance pool drain tracer.
 *
 * Resolves the world-load 0x4CC064 crash fork without any engine detour.
 *
 * The crash is a NULL pop from a FIXED one-shot TEXTURE-COMPONENT pool
 * (live-disasm + WAD-differential proven, 2026-06-14):
 *   ctor path @0x4cbf00 fills it ONCE with 5120 cells (0x54 bytes each, vtable
 *   0xBB1090) via filler FUN_004cbf60 (edi=0x400 iters x 5 cells); cap +0x78014
 *   is set to 0x1400=5120. NOTHING ever pushes a cell back (one-shot). Pop
 *   FUN_004cc030 decrements the count; when count==0 it reads the fallback slot
 *   +0x7800c (zero-inited, never set) -> NULL -> mov eax,[esi] (esi=0) -> AV
 *   @0x4CC064. The pop is reached via the dedup INSERT FUN_004cc130 (hashes the
 *   texture key with FUN_008242b0(0x1400); an OCCUPIED bucket reuses its cell and
 *   does NOT pop -> the pool drains by DISTINCT texture key, type tag 0xF011157A).
 *   (NOTE: the earlier "driver FUN_004ac8e0 pops one cell per +0x1c record" claim
 *   was WRONG -- FUN_004ac8e0 allocs count*0x400 via Chunk_Alloc + parses MTRL and
 *   does not touch this pool; verified by disasm. So this is NOT a converter
 *   inflated-count bug.)
 *
 * VERDICT (settled): T2 BUDGET. The DLC overlay's spawn region legitimately
 * registers >5120 distinct texture components (base streams each region <5120;
 * DLC adds new texture keys on top). Per-block max texcomp records is 62 (patch)
 * / 223 (base) -> no single inflated block (T1 ruled out). PC cap is 5120 (proven
 * two ways: ctor `mov [0x16ce8c4],0x1400` and the crash-dump [EAX]=...,0x1400).
 *
 * This file provides TWO things:
 *   1. InstallPoolProbe()       -- poll-only free-count tracer (diagnostic).
 *   2. InstallPoolOverflowFix() -- the FIX: a MinHook detour on the pop that
 *      hands back a fresh 0x54 cell when the free-list is empty, instead of the
 *      NULL fallback. The pop's existing per-cell ctor (FUN_004b0ec0) + vtable[0]
 *      vcall then run normally on the fresh cell, so the world loads past 5120.
 *      (Approach A: minimal/localized. If textures beyond 5120 glitch, the
 *      heavier follow-up is relocating the whole pool to a larger arena.)
 *
 * Pool globals (absolute; exe is non-relocatable, base 0x400000):
 *   base DAT_016568b0 = 0x016568B0  (first dword = vtable ptr -> 0x00BB1090)
 *   free-count  base+0x78010 = 0x016CE8C0   (5120 after fill, --> 0 at crash)
 *   capacity    base+0x78014 = 0x016CE8C4   (== 0x1400 once initialized)
 *   fallback    base+0x7800c = 0x016CE8BC   (the NULL slot popped at exhaustion)
 *   free-list   base+0x7300c                 (5120 cell ptrs, consumed by the pop)
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#include "MinHook.h"

extern void pmc_log(const char *source, const char *fmt, ...);
extern void pmc_log_flush(void);
extern void cc_tracer_dump(const char *why);   /* cc_tracer.c — insert histogram */

#define POOL_BASE      0x016568B0u
#define POOL_FREECNT   0x016CE8C0u
#define POOL_CAP       0x016CE8C4u
#define POOL_FALLBACK  0x016CE8BCu
#define POOL_VTABLE    0x00BB1090u   /* expected first-dword target of base    */

#define POLL_MS        10u           /* fast enough to resolve burst vs gradual */
#define HEARTBEAT_MS   1000u
#define BURST_DROP     256           /* a one-tick drop >= this == T1 signal    */
#define LOW_WATERMARK  512           /* start logging every change below this   */

static DWORD rd32(DWORD a) { return *(volatile DWORD *)a; }

static DWORD WINAPI PoolWatchThread(LPVOID arg)
{
    int    inited      = 0;
    DWORD  last_free   = 0;
    DWORD  min_free    = 0xFFFFFFFFu;
    DWORD  hb_accum    = 0;
    int    hit_zero    = 0;
    (void)arg;

    for (;;) {
        DWORD cap, vtbl, free_now;
        Sleep(POLL_MS);
        hb_accum += POLL_MS;

        /* Gate on the pool being constructed: capacity must read 0x1400 and the
         * base's first dword must point at the pool vtable. Until then the
         * globals are uninitialized bss and must not be interpreted. */
        if (!inited) {
            cap  = rd32(POOL_CAP);
            vtbl = rd32(POOL_BASE);
            if (cap != 0x1400u || vtbl != POOL_VTABLE)
                continue;
            inited   = 1;
            last_free = rd32(POOL_FREECNT);
            min_free  = last_free;
            pmc_log("pool", "render-instance pool initialized: cap=%lu free=%lu "
                    "(base=%08X freecnt@%08X). Tracing drain; BURST>=%d => T1 "
                    "(converter inflated count), gradual => T2 (budget). [pool]",
                    cap, last_free, POOL_BASE, POOL_FREECNT, BURST_DROP);
            pmc_log_flush();
            continue;
        }

        free_now = rd32(POOL_FREECNT);
        if (free_now == last_free) {
            if (hb_accum >= HEARTBEAT_MS) {
                pmc_log("pool", "free=%lu (min=%lu)", free_now, min_free);
                hb_accum = 0;
            }
            continue;
        }

        /* free-count changed: detect bursts (large single-tick drops) and the
         * approach to empty. A burst is the T1 fingerprint. */
        if (free_now < last_free) {
            DWORD drop = last_free - free_now;
            if (drop >= BURST_DROP) {
                pmc_log("pool", "*** BURST drop %lu -> %lu (-%lu) in one %ums tick "
                        "== T1 signature (single object draining the pool) ***",
                        last_free, free_now, drop, POLL_MS);
                pmc_log_flush();
                cc_tracer_dump("BURST");   /* attribute the drain to its callers */
            } else if (free_now <= LOW_WATERMARK || free_now < min_free) {
                pmc_log("pool", "free %lu -> %lu (-%lu)", last_free, free_now, drop);
            }
        } else {
            /* count went UP: a bulk refill (level teardown re-ran the filler). */
            pmc_log("pool", "free REFILLED %lu -> %lu", last_free, free_now);
        }

        if (free_now < min_free) min_free = free_now;
        if (free_now == 0 && !hit_zero) {
            hit_zero = 1;
            pmc_log("pool", "*** free-count == 0 : pool EXHAUSTED. next pop "
                    "returns NULL fallback @%08X -> 0x4CC064 crash imminent ***",
                    POOL_FALLBACK);
            pmc_log_flush();
            cc_tracer_dump("EXHAUSTED");
        }
        last_free = free_now;
        hb_accum  = 0;
    }
    return 0;
}

int InstallPoolProbe(void)
{
    HANDLE h = CreateThread(NULL, 0, PoolWatchThread, NULL, 0, NULL);
    if (h)
        CloseHandle(h);
    pmc_log("pool", "render-instance pool drain tracer armed (polls freecnt "
            "@[0x%08X] every %ums once pool cap==0x1400). Source [pool].",
            POOL_FREECNT, POLL_MS);
    pmc_log_flush();
    return 1;
}

/* ===========================================================================
 *  THE FIX — allocate-on-demand pop detour (approach A)
 *
 *  FUN_004cc030 is the pool pop: __thiscall(pool in ecx, param_2 on stack),
 *  ret 4. Original body (live disasm):
 *      eax = pool[+0x78010]                  ; free count
 *      if (eax == 0) esi = *(pool+0x7800c)   ; fallback slot = NULL -> CRASH
 *      else { eax--; pool[+0x78010]=eax; esi = *(pool+0x7300c + eax*4); }
 *      if (esi) FUN_004b0ec0(esi)            ; per-cell ctor (sets cell vtable)
 *      esi->vtable[0](param_2)               ; mov eax,[esi]; call [eax]  <-- 0x4cc064
 *      return esi
 *  We reimplement it faithfully and, on the empty branch, hand back a fresh
 *  zeroed 0x54 cell instead of the NULL fallback. The ctor + vcall then run
 *  exactly as the engine expects (a real pooled cell is likewise a zeroed 0x54
 *  region that FUN_004b0ec0 initializes on pop). The fast path is byte-for-byte
 *  the original (unlocked, matching the engine's own non-atomic pop).
 * ======================================================================== */

#define POOL_POP_VA        0x004CC030u   /* FUN_004cc030 — the pop                */
#define CELL_CTOR_VA       0x004B0EC0u   /* FUN_004b0ec0 — per-cell ctor (ecx=cell)*/
#define POOL_CNT_OFF       0x78010u      /* free count                            */
#define POOL_FREELIST_OFF  0x7300Cu      /* free-list array of cell ptrs          */
#define CELL_SIZE          0x54u
#define OVF_SLAB_BYTES     0x10000u      /* 64KB slab ~ 776 cells per VirtualAlloc */

typedef void (__attribute__((thiscall)) *cell_ctor_fn) (void *cell);
typedef void (__attribute__((thiscall)) *cell_vcall_fn)(void *cell, void *param_2);

static CRITICAL_SECTION g_ovfLock;
static char  *g_ovfSlab   = NULL;
static SIZE_T g_ovfUsed   = 0;
static SIZE_T g_ovfSlabSz = 0;
static volatile LONG g_ovfCells = 0;

/* Fresh 0x54 cell from a bump allocator over 64KB VirtualAlloc slabs. These are
 * never freed — like the engine's own pool, this allocation is one-shot for the
 * world's lifetime. Zeroed (VirtualAlloc guarantees zero). */
static void *AllocOverflowCell(void)
{
    void *cell;
    EnterCriticalSection(&g_ovfLock);
    if (g_ovfSlab == NULL || g_ovfUsed + CELL_SIZE > g_ovfSlabSz) {
        g_ovfSlab   = (char *)VirtualAlloc(NULL, OVF_SLAB_BYTES,
                                           MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
        g_ovfUsed   = 0;
        g_ovfSlabSz = (g_ovfSlab ? OVF_SLAB_BYTES : 0);
    }
    if (g_ovfSlab == NULL) { LeaveCriticalSection(&g_ovfLock); return NULL; }
    cell = g_ovfSlab + g_ovfUsed;
    g_ovfUsed += CELL_SIZE;
    LeaveCriticalSection(&g_ovfLock);
    return cell;
}

static void *(__attribute__((thiscall)) *g_realPop)(void *pool, void *param_2) = NULL;

static void *__attribute__((thiscall)) Pop_hook(void *pool, void *param_2)
{
    DWORD *pcount = (DWORD *)((char *)pool + POOL_CNT_OFF);
    void  *cell;

    if (*pcount != 0) {
        /* fast path: identical to the original free-list pop (unlocked, as orig) */
        DWORD n = *pcount - 1;
        *pcount = n;
        cell = *(void **)((char *)pool + POOL_FREELIST_OFF + n * 4);
    } else {
        /* exhaustion — the crash branch. Serve a fresh cell instead of NULL. */
        cell = AllocOverflowCell();
        LONG total = InterlockedIncrement(&g_ovfCells);
        if (total == 1 || (total & 0x3FFu) == 0) {
            pmc_log("pool", "render pool past 5120 cap — serving overflow cell #%ld "
                    "(no 0x4CC064 crash). Expand pool if surplus textures glitch. [pool]",
                    total);
            pmc_log_flush();
        }
    }

    if (cell != NULL) {
        ((cell_ctor_fn)CELL_CTOR_VA)(cell);                    /* sets cell->vtable */
        ((cell_vcall_fn)(*(void ***)cell)[0])(cell, param_2);  /* cell->vtable[0]() */
    }
    return cell;
}

int InstallPoolOverflowFix(void)
{
    MH_STATUS st;

    InitializeCriticalSection(&g_ovfLock);

    st = MH_Initialize();   /* idempotent — also init'd by lua_log_hook */
    if (st != MH_OK && st != MH_ERROR_ALREADY_INITIALIZED) {
        pmc_log("pool", "overflow-fix MH_Initialize failed: %s", MH_StatusToString(st));
        return 0;
    }
    st = MH_CreateHook((LPVOID)POOL_POP_VA, (LPVOID)Pop_hook, (LPVOID *)&g_realPop);
    if (st != MH_OK) {
        pmc_log("pool", "overflow-fix MH_CreateHook(0x%08X) failed: %s",
                POOL_POP_VA, MH_StatusToString(st));
        return 0;
    }
    st = MH_EnableHook((LPVOID)POOL_POP_VA);
    if (st != MH_OK) {
        pmc_log("pool", "overflow-fix MH_EnableHook(0x%08X) failed: %s",
                POOL_POP_VA, MH_StatusToString(st));
        return 0;
    }
    pmc_log("pool", "render-pool overflow fix ARMED: pop @0x%08X serves fresh "
            "0x%X-byte cells past the 5120 cap (kills the NULL-fallback crash "
            "@0x4CC064). Source [pool].", POOL_POP_VA, CELL_SIZE);
    pmc_log_flush();
    return 1;
}
