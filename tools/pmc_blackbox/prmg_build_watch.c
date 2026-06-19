/* prmg_build_watch.c — NON-MUTATING diagnostic for the 0x47A7C6 / 0x47AA5C
 * render-time crash on a terrain primitive-group element (vtable 0x00BAB258,
 * 0x1C4-stride element array, count = top-level INFO[0]).
 *
 * Static RCA (tools/prmg_count_scan.py + prmg_invariant_scan.py over 65,942 retail
 * + 6,998 converted PRMGs) proved the converted terrain meshes are STRUCTURALLY
 * SOUND: INFO[0]==#PRMG, descriptor walk reaches every PRMG, per-PRMG stream sizes
 * consistent, sub-chunk shape identical to retail. So the build SHOULD produce
 * valid elements; the garbage element[1] seen at render time must therefore be
 * either (a) garbage straight out of the builder (static analysis has a gap), or
 * (b) a heap OVERWRITE between build and render. This probe distinguishes the two
 * WITHOUT changing engine behaviour:
 *
 *   1. MinHook FUN_00478120 (the renderable element-array builder). Run the real
 *      build via the trampoline, then validate every built element's record+0 and
 *      record+4 against the shared 256-slot render-resource handle table
 *      (DAT_0197da48). A valid handle is always one of those table entries.
 *        - Any element foreign at build  -> log it + the asset's identifying key
 *          (elem+0x160 = the record+0 lookup key INFO+0x24). => BUILD-TIME bug,
 *          and we have named the asset.
 *        - Clean elements -> snapshot the LAST element's {addr,rec0,rec4,key} so
 *          the crash handler can compare build-time vs render-time values.
 *   2. prmg_bw_report_element(edi) — called from crash_handler.c dump path: if the
 *      crashing element was recorded CLEAN at build but now reads foreign, that is
 *      a proven heap OVERWRITE (and we print the before/after); if it was never
 *      recorded clean, the garbage came from the builder.
 *
 * Read-only: VirtualQuery-gated loads, no game memory is written, no control flow
 * is altered. Opt out with -DPMC_DISABLE_PRMG_BUILD_WATCH.
 */
#include <windows.h>
#include <stdio.h>
#include "MinHook.h"

extern void pmc_log(const char *source, const char *fmt, ...);
extern void pmc_log_flush(void);

#define FN_478120     0x00478120u   /* renderable element-array builder (__thiscall) */
#define VT_TERRAIN    0x00BAB258u   /* the crashing renderable's vtable */
#define ELEM_STRIDE   0x1C4u
#define OFF_COUNT     0x04u         /* this+4  = element count                       */
#define OFF_ARRAY     0x08u         /* this+8  = element array base                  */
#define OFF_KEY       0x160u        /* elem+0x160 = record+0 key (INFO+0x24), stable */
#define OFF_BINDCNT   0x1B4u        /* elem+0x1b4 = binding-index count              */
#define OFF_BINDPTR   0x1B8u        /* elem+0x1b8 = binding-index array ptr          */
#define OFF_KEY4      0x16Cu        /* elem+0x16c = record+4 key  (INFO+0x20)        */
#define OFF_KEY0      0x170u        /* elem+0x170 = record+0 key  (INFO+0x24)        */
#define HNDTAB        0x0197DA48u   /* 256-slot render-resource handle table         */
#define KEYTAB        0x0197DE48u   /* 256-slot render-resource KEY table (parallel) */

typedef void(__fastcall *fn_478120_t)(void *thiz, void *edx, int p2, int p3);
static fn_478120_t g_orig_478120 = NULL;

/* ---- read-only memory helpers ------------------------------------------- */
static int rd_ok(DWORD addr, DWORD len)
{
    MEMORY_BASIC_INFORMATION mbi;
    DWORD p, end = addr + len;
    if (addr < 0x10000u || end < addr) return 0;
    for (p = addr & ~0xFFFu; p < end; p += 0x1000u) {
        if (VirtualQuery((LPCVOID)p, &mbi, sizeof mbi) == 0) return 0;
        if (mbi.State != MEM_COMMIT) return 0;
        if (mbi.Protect & (PAGE_NOACCESS | PAGE_GUARD)) return 0;
    }
    return 1;
}
static DWORD rd32(DWORD addr) { return rd_ok(addr, 4) ? *(const DWORD *)addr : 0xFFFFFFFFu; }

/* A valid PRMG record+0/+4 handle is one of the 256 render-resource table entries
 * (or the 0 sentinel = a *different*, registry-MISS failure, not "wild garbage").
 * Returns 1 if `h` is a non-zero value absent from the table = foreign/garbage. */
static int handle_foreign(DWORD h)
{
    const DWORD *t = (const DWORD *)HNDTAB;
    int i;
    if (h == 0) return 0;
    if (!rd_ok(HNDTAB, 256 * 4)) return 0;   /* can't tell -> don't cry wolf */
    for (i = 0; i < 256; i++) if (t[i] == h) return 0;
    return 1;
}

/* FUN_008242b0 semantics: slot = key % 256, linear-probe <=8 slots; return slot
 * if KEYTAB[slot]==key, else 0xFFFFFFFF. Reproduce the find to classify a key. */
static int key_slot(DWORD key)
{
    const DWORD *kt = (const DWORD *)KEYTAB;
    DWORD base, i;
    if (key == 0) return -1;
    if (!rd_ok(KEYTAB, 256 * 4)) return -1;
    base = key % 256u;
    if (base + 8u >= 256u) {                 /* engine bails the fast 8-probe near wrap */
        for (i = 0; i < 256; i++) if (kt[i] == key) return (int)i;
        return -1;
    }
    for (i = 0; i < 8; i++) {
        DWORD v = kt[base + i];
        if (v == key) return (int)(base + i);
        if (v == 0)   return -1;
    }
    return -1;
}
static DWORD bswap32(DWORD x) { return __builtin_bswap32(x); }

/* For a PRMG element whose record+4 missed the registry, classify the miss.
 * The two INFO keys persist in the element (stored at parse time, never
 * overwritten) even after record+4 is cleared to NULL, so this works at crash
 * time too. We DON'T trust a single stored offset: scan the +0x140..+0x184
 * window and, for every dword, report whether it resolves in the key table
 * as-is (a live key, like the working record+0 key) or only after a byteswap
 * (=> CONVERTER mangled it, fork a). Neither anywhere => UNREGISTERED (fork b). */
static void diagnose_key_miss(DWORD elem, DWORD i, DWORD rec0, DWORD rec4)
{
    DWORD off, w;
    int found_live = 0, found_bswap = 0;
    char line[256]; int n;

    pmc_log("prmg-key", "MISS elem[%lu]@%08lX rec0=%08lX rec4=%08lX  (keys @+16c/+170)",
            i, elem, rec0, rec4);
    /* named candidates first */
    {
        DWORD k0 = rd32(elem + OFF_KEY0), k4 = rd32(elem + OFF_KEY4);
        pmc_log("prmg-key", "  key0(+170)=%08lX slot=%d  key4(+16c)=%08lX slot=%d bswap(key4)=%08lX bslot=%d",
                k0, key_slot(k0), k4, key_slot(k4), bswap32(k4), key_slot(bswap32(k4)));
    }
    /* window scan with per-dword resolution verdict */
    n = 0; line[0] = 0;
    for (off = 0x140; off <= 0x184; off += 4) {
        w = rd32(elem + off);
        int s = key_slot(w), bs = key_slot(bswap32(w));
        const char *tag = s >= 0 ? "=LIVE" : bs >= 0 ? "=BSWAP!" : "";
        if (s >= 0) found_live = 1;
        if (s < 0 && bs >= 0) found_bswap = 1;
        n += wsprintfA(line + n, " +%lX:%08lX%s", off, w, tag);
        if (n > 180) { pmc_log("prmg-key", "  win:%s", line); n = 0; line[0] = 0; }
    }
    if (n) pmc_log("prmg-key", "  win:%s", line);
    pmc_log("prmg-key", "  VERDICT: %s",
            found_bswap ? "*** a key resolves ONLY byteswapped => CONVERTER mangled record+4 key (fork a) ***"
            : found_live ? "all candidate keys are live as-is => record+4 key is a clean miss / UNREGISTERED or a runtime registry-eviction (fork b)"
            : "no candidate resolves either way => keys not at expected offset, inspect win above");
    pmc_log_flush();
}

/* Crash-time entry: given the renderable `this`, find the element(s) with a NULL
 * record (the 0x47AA5C miss) and classify their keys. Reads only. */
__declspec(dllexport) void prmg_bw_diagnose_renderable(DWORD thiz)
{
    DWORD count, arr, i;
    if (!rd_ok(thiz, 0x10) || *(const DWORD *)thiz != VT_TERRAIN) {
        pmc_log("prmg-key", "renderable %08lX not the 0x%08X terrain class; skip", thiz, VT_TERRAIN);
        pmc_log_flush();
        return;
    }
    count = *(const DWORD *)(thiz + OFF_COUNT);
    arr   = *(const DWORD *)(thiz + OFF_ARRAY);
    if (arr == 0 || count == 0 || count > 4096) return;
    for (i = 0; i < count; i++) {
        DWORD elem = arr + i * ELEM_STRIDE;
        DWORD r0, r4;
        if (!rd_ok(elem, ELEM_STRIDE)) continue;
        r0 = rd32(elem); r4 = rd32(elem + 4);
        if (r4 == 0 || r0 == 0) diagnose_key_miss(elem, i, r0, r4);
    }
}

/* ===========================================================================
 * Registry-lookup key capture: the record+4 key isn't stored in the element, so
 * intercept FUN_008242b0 (the hash-find) itself. It's a PURE table read (table
 * base in ESI, key in ECX, size on the stack; returns slot or -1) — we reimplement
 * it EXACTLY and return that, so the game's behaviour is unchanged, and we log +
 * classify the misses whose caller is the mesh builder FUN_00478270 (0x4783xx).
 * ======================================================================== */
#define FN_8242B0  0x008242B0u

/* Byte-exact port of FUN_008242b0. */
static DWORD reg_find(DWORD esi, DWORD key, DWORD size)
{
    const DWORD *t = (const DWORD *)esi;
    DWORD start, u3, u4, v, i;
    if (key == 0 || size == 0) return 0xFFFFFFFFu;
    if (!rd_ok(esi, size * 4)) return 0xFFFFFFFFu;
    start = key % size;
    u4 = start;
    if (start + 8 < size) {
        for (i = 0; i < 7; i++) {
            v = t[start + i];
            if (v == key) return start + i;
            if (v == 0)   return 0xFFFFFFFFu;
        }
        v = t[start + 7];
        if (v == key) return start + 7;
        u3 = start + 8; u4 = start + 8;
        if (v == 0) return 0xFFFFFFFFu;
    } else {
        u3 = start;
    }
    for (;;) {
        if (size <= u3) {
            DWORD u2 = 0;
            if (u4 != 0) {
                do {
                    v = t[u2];
                    if (v == key) return u2;
                } while (v != 0 && (++u2 < u4));
            }
            return 0xFFFFFFFFu;
        }
        v = t[u3];
        if (v == key) return u3;
        if (v == 0) return 0xFFFFFFFFu;
        u3++;
    }
}

typedef DWORD(__fastcall *fn_8242b0_t)(DWORD key, DWORD edx, DWORD size);
static fn_8242b0_t g_orig_8242b0 = NULL;
static volatile LONG g_keylog = 0;

static DWORD __fastcall Hook_8242b0(DWORD key, DWORD edx, DWORD size)
{
    DWORD esi, ret, slot;
    __asm__ volatile ("movl %%esi, %0" : "=r"(esi));   /* table base, captured first */
    ret  = (DWORD)(ULONG_PTR)__builtin_return_address(0);
    slot = reg_find(esi, key, size);
    (void)edx;
    if (ret >= 0x00478000u && ret < 0x00479000u && (LONG)slot < 0) {
        if (InterlockedIncrement(&g_keylog) <= 40) {
            DWORD bsw = bswap32(key);
            DWORD bslot = reg_find(esi, bsw, size);
            pmc_log("prmg-key2", "FUN_00478270 lookup MISS caller=%08lX key=%08lX tbl=%08lX size=%lX "
                    "| bswap=%08lX bslot=%ld => %s",
                    ret, key, esi, size, bsw, (LONG)bslot,
                    (LONG)bslot >= 0 ? "*** byteswap RESOLVES => CONVERTER mangled the key (fork a) ***"
                                     : "clean miss => key absent => UNREGISTERED resource (fork b)");
            pmc_log_flush();
        }
    }
    return slot;
}

/* ---- snapshot of clean last-elements (for build-vs-crash compare) -------- */
typedef struct { DWORD addr, rec0, rec4, key; } Snap;
#define SNAP_CAP 2048
static Snap g_snap[SNAP_CAP];
static volatile LONG g_snapN = 0;

static LONG g_built = 0, g_garbage = 0;

static void snap_record(DWORD addr, DWORD rec0, DWORD rec4, DWORD key)
{
    LONG idx = InterlockedIncrement(&g_snapN) - 1;
    if (idx < SNAP_CAP) { g_snap[idx].addr = addr; g_snap[idx].rec0 = rec0;
                          g_snap[idx].rec4 = rec4; g_snap[idx].key = key; }
}

/* Called from crash_handler.c with the crashing element (EDI). */
__declspec(dllexport) void prmg_bw_report_element(DWORD edi)
{
    LONG n = g_snapN, i;
    DWORD now0 = rd32(edi), now4 = rd32(edi + 4);
    for (i = 0; i < n && i < SNAP_CAP; i++) {
        if (g_snap[i].addr == edi) {
            pmc_log("crash", "  [prmg-bw] elem %08lX was CLEAN AT BUILD "
                    "(rec0=%08lX rec4=%08lX key=%08lX); NOW rec0=%08lX rec4=%08lX => %s",
                    edi, g_snap[i].rec0, g_snap[i].rec4, g_snap[i].key, now0, now4,
                    (now0 != g_snap[i].rec0 || now4 != g_snap[i].rec4)
                        ? "HEAP OVERWRITE (post-build corruption)"
                        : "unchanged (not an overwrite)");
            pmc_log_flush();
            return;
        }
    }
    pmc_log("crash", "  [prmg-bw] elem %08lX NOT in clean-build snapshot "
            "(%ld terrain renderables built, %ld had garbage at build) => "
            "garbage originated AT/IN the builder, not a later overwrite",
            edi, g_built, g_garbage);
    pmc_log_flush();
}

/* ---- post-build inspection ---------------------------------------------- */
static void inspect_built(DWORD thiz)
{
    DWORD vt, count, arr, i, bad_seen = 0;

    if (!rd_ok(thiz, 0x10)) return;
    vt = *(const DWORD *)thiz;
    if (vt != VT_TERRAIN) return;            /* focus on the crashing class */

    count = *(const DWORD *)(thiz + OFF_COUNT);
    arr   = *(const DWORD *)(thiz + OFF_ARRAY);
    if (arr == 0 || count == 0 || count > 4096) return;
    InterlockedIncrement(&g_built);

    for (i = 0; i < count; i++) {
        DWORD elem = arr + i * ELEM_STRIDE;
        DWORD rec0, rec4, key, bc, bp;
        if (!rd_ok(elem, ELEM_STRIDE)) {
            pmc_log("prmg-bw", "BUILT vt=%08lX count=%lu elem[%lu]@%08lX UNREADABLE",
                    vt, count, i, elem);
            bad_seen = 1;
            continue;
        }
        rec0 = *(const DWORD *)elem;
        rec4 = *(const DWORD *)(elem + 4);
        key  = *(const DWORD *)(elem + OFF_KEY);
        bc   = *(const DWORD *)(elem + OFF_BINDCNT);
        bp   = *(const DWORD *)(elem + OFF_BINDPTR);
        /* registry-MISS signature (the 0x47AA5C crash): record+4 == NULL because
         * its key didn't resolve in the 256-slot registry. NULL is the miss
         * sentinel — handle_foreign() ignores it — so detect it explicitly and
         * dump both INFO keys to classify converter-mangled (fork a) vs
         * unregistered (fork b). Also covers a NULL record+0. */
        if (rec4 == 0 || rec0 == 0) {
            pmc_log("prmg-bw", "REGISTRY-MISS vt=%08lX count=%lu elem[%lu]@%08lX "
                    "rec0=%08lX rec4=%08lX", vt, count, i, elem, rec0, rec4);
            diagnose_key_miss(elem, i, rec0, rec4);
            bad_seen = 1;
        }
        /* garbage signature: record+0/+4 a wild non-null ptr, or a binding array
         * that is non-empty but unreadable. */
        else if (handle_foreign(rec0) || handle_foreign(rec4) ||
            (bc != 0 && bc < 0x100000u && bp != 0 && !rd_ok(bp, 4))) {
            pmc_log("prmg-bw", "GARBAGE-AT-BUILD vt=%08lX count=%lu elem[%lu]@%08lX "
                    "rec0=%08lX%s rec4=%08lX%s key=%08lX bindcnt=%lu bindptr=%08lX",
                    vt, count, i, elem,
                    rec0, handle_foreign(rec0) ? "(foreign)" : "",
                    rec4, handle_foreign(rec4) ? "(foreign)" : "",
                    key, bc, bp);
            bad_seen = 1;
        } else if (i == count - 1) {
            /* clean last element: snapshot for the crash-time compare */
            snap_record(elem, rec0, rec4, key);
        }
    }
    if (bad_seen) {
        DWORD k0 = rd32(arr + OFF_KEY);   /* element[0] key = asset identity */
        InterlockedIncrement(&g_garbage);
        pmc_log("prmg-bw", "  ^ asset id (element[0] key INFO+0x24) = %08lX  this=%08lX",
                k0, thiz);
        pmc_log_flush();
    }
}

static void __fastcall Hook_478120(void *thiz, void *edx, int p2, int p3)
{
    g_orig_478120(thiz, edx, p2, p3);   /* run the real build */
    inspect_built((DWORD)thiz);
}

int InstallPrmgBuildWatch(void)   /* called from pmc_blackbox.c */
{
#ifdef PMC_DISABLE_PRMG_BUILD_WATCH
    pmc_log("prmg-bw", "build-watch DISABLED at compile time");
    return 0;
#else
    MH_STATUS st = MH_Initialize();
    if (st != MH_OK && st != MH_ERROR_ALREADY_INITIALIZED) {
        pmc_log("prmg-bw", "MH_Initialize failed: %s", MH_StatusToString(st));
        return 0;
    }
    st = MH_CreateHook((LPVOID)FN_478120, (LPVOID)&Hook_478120,
                       (LPVOID *)&g_orig_478120);
    if (st != MH_OK) {
        pmc_log("prmg-bw", "MH_CreateHook(0x%08X) failed: %s", FN_478120,
                MH_StatusToString(st));
        return 0;
    }
    st = MH_EnableHook((LPVOID)FN_478120);
    if (st != MH_OK) {
        pmc_log("prmg-bw", "MH_EnableHook failed: %s", MH_StatusToString(st));
        return 0;
    }
    pmc_log("prmg-bw", "build-watch ARMED on FUN_00478120: validates each built "
            "0x%08X element vs the 256-slot handle table; logs garbage-at-build + "
            "snapshots clean elements for the crash-time overwrite compare.", VT_TERRAIN);
    /* NOTE: the global FUN_008242b0 replacement was REVERTED — capturing the
     * caller-set ESI table base from a C hook proved unreliable and returned wrong
     * slots, breaking every registry lookup (instant EIP=0 crash). Hook_8242b0 /
     * reg_find are retained for a future TARGETED call-site capture only. */
    (void)&Hook_8242b0; (void)&g_orig_8242b0;
    pmc_log_flush();
    return 1;
#endif
}
