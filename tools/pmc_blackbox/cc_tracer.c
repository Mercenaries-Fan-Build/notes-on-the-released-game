/* cc_tracer.c — texture-component INSERT tracer (the 0x4CC064 pool drain).
 *
 * The render-instance/texture-component pool (5120 cells) drains one cell per
 * DISTINCT texture key inserted via FUN_004cc130 (dedup find on FUN_008242b0,
 * 5120 buckets; an empty slot pops a fresh cell via vtable[0x1c]). A BURST drop
 * (pool_probe T1) means ~N cells consumed in one 10ms tick. This tracer answers
 * WHO drives it and WHETHER the keys are distinct:
 *   - one dominant caller with distinct keys  => a single object iterating an
 *     inflated texture list (a real converter/count bug to fix), or
 *   - many callers / a layer-load spread       => genuine capacity (>5120 distinct
 *     textures legitimately resident; fix = pool expansion or trimming the set).
 *
 * Non-mutating: it runs the original insert unchanged and only tallies. The tally
 * is dumped (cc_tracer_dump) by pool_probe at the burst and at exhaustion so the
 * histogram is correlated with the drain.
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include "MinHook.h"

extern void pmc_log(const char *source, const char *fmt, ...);
extern void pmc_log_flush(void);

#define FN_CC130   0x004CC130u

typedef int(__fastcall *fn_cc130_t)(int *pool, int edx, int comp);
static fn_cc130_t g_orig_cc130 = NULL;

/* caller histogram (immediate return address of FUN_004cc130) */
#define HIST_N 96
static struct { DWORD caller; LONG count; } g_hist[HIST_N];
static volatile LONG g_total = 0;

/* distinct-key set (open addressing) to count UNIQUE texture hashes = the real
 * resident-texture-component demand. Key = component+0 (the texture hash; +4 is
 * the constant type tag 0xF011157A, which is what the old sample wrongly read). */
#define KSET_SLOTS 16384u           /* power of two; > the ~5618 expected keys     */
static DWORD g_kset[KSET_SLOTS];
static volatile LONG g_distinct = 0;

/* insert key into the set; returns 1 if it was NEW. Single-threaded-ish (world
 * load); a rare race only mis-counts by a few, which doesn't change the verdict. */
static int kset_add(DWORD key)
{
    DWORD h = (key * 2654435761u) & (KSET_SLOTS - 1);
    DWORD i;
    if (key == 0) return 0;
    for (i = 0; i < KSET_SLOTS; i++) {
        DWORD slot = (h + i) & (KSET_SLOTS - 1);
        if (g_kset[slot] == key) return 0;       /* already present */
        if (g_kset[slot] == 0) { g_kset[slot] = key; InterlockedIncrement(&g_distinct); return 1; }
    }
    return 0;
}

static int rd4(DWORD a, DWORD *out)
{
    MEMORY_BASIC_INFORMATION mbi;
    if (a < 0x10000u) return 0;
    if (VirtualQuery((LPCVOID)a, &mbi, sizeof mbi) == 0) return 0;
    if (mbi.State != MEM_COMMIT || (mbi.Protect & (PAGE_NOACCESS | PAGE_GUARD))) return 0;
    *out = *(const DWORD *)a;
    return 1;
}

/* heuristic: is this "hash" obviously NOT a texture hash (= overrun garbage)? */
static int garbage_shaped(DWORD k)
{
    if (k < 0x10000u) return 1;                                    /* tiny / packed   */
    if ((k & 0xFFFFu) == 0xFFFFu || (k & 0xFFFF0000u) == 0xFFFF0000u) return 1; /* sentinel */
    if ((k & 0xFF00FF00u) == 0 && (k >> 16) < 0x300u && (k & 0xFFFFu) < 0x300u
        && (k & 0x00FF00FFu)) return 1;                           /* widechar pair   */
    if ((k >= 0x30000000u && k <= 0x48000000u)
        || (k >= 0xB0000000u && k <= 0xC8000000u)) return 1;      /* param float     */
    if (k == 0xAAAAAAAAu || k == 0xCCCCCCCCu || k == 0xBBBBBBBBu) return 1; /* uninit   */
    return 0;
}
static volatile LONG g_ctxdumps = 0;

static int __fastcall Hook_cc130(int *pool, int edx, int comp)
{
    DWORD ret = (DWORD)(ULONG_PTR)__builtin_return_address(0);
    DWORD k;
    int i;
    InterlockedIncrement(&g_total);
    for (i = 0; i < HIST_N; i++) {
        if (g_hist[i].caller == ret) { InterlockedIncrement(&g_hist[i].count); break; }
        if (g_hist[i].caller == 0)  { g_hist[i].caller = ret; g_hist[i].count = 1; break; }
    }
    /* record the texture hash (component+0) into the distinct-key set */
    if (rd4((DWORD)comp + 0, &k)) {
        kset_add(k);
        /* on the first few GARBAGE inserts, dump the component's neighborhood so we
         * can see the over-counted array (where real {hash,F011157A,0} records end
         * and param-floats/strings begin) and identify the source structure. */
        if (garbage_shaped(k) && InterlockedIncrement(&g_ctxdumps) <= 6) {
            DWORD base = (DWORD)comp - 0x40, off, c4 = 0;
            char line[256]; int o = 0;
            rd4((DWORD)comp + 4, &c4);
            pmc_log("cc", "GARBAGE comp@%08lX key=%08lX +4=%08lX caller=%08lX pool=%08lX",
                    (DWORD)comp, k, c4, ret, (DWORD)pool);
            for (off = 0; off <= 0x60; off += 4) {
                DWORD w = 0; DWORD a = base + off;
                if (rd4(a, &w)) o += wsprintfA(line + o, " %s%08lX", a == (DWORD)comp ? ">" : "", w);
                else            o += wsprintfA(line + o, " ????????");
                if (o > 200) { pmc_log("cc", "  ctx:%s", line); o = 0; line[0] = 0; }
            }
            if (o) pmc_log("cc", "  ctx:%s", line);
            pmc_log_flush();
        }
    }
    return g_orig_cc130(pool, edx, comp);   /* run the real insert unchanged */
}

__declspec(dllexport) void cc_tracer_dump(const char *why)
{
    int i, j, top, distinct = 0;
    pmc_log("cc", "=== insert histogram (%s) total_inserts=%ld ===", why, g_total);
    /* print callers by descending count (simple selection, up to 10) */
    for (top = 0; top < 10; top++) {
        int best = -1; LONG bc = 0;
        for (i = 0; i < HIST_N && g_hist[i].caller; i++)
            if (g_hist[i].count > bc) { bc = g_hist[i].count; best = i; }
        if (best < 0 || bc == 0) break;
        pmc_log("cc", "  caller=%08lX count=%ld", g_hist[best].caller, g_hist[best].count);
        g_hist[best].count = -g_hist[best].count;   /* mark consumed for this dump */
    }
    for (i = 0; i < HIST_N; i++) if (g_hist[i].count < 0) g_hist[i].count = -g_hist[i].count;
    /* distinct texture hashes = the real resident demand (vs the fixed 5120 pool) */
    pmc_log("cc", "  DISTINCT texture hashes inserted: %ld (pool cap 5120) => %s",
            g_distinct,
            g_distinct > 5120 ? "exceeds pool: capacity OR divergent-hash inflation"
                              : "fits pool");
    /* dump every distinct hash (compact) so we can offline-check base-WAD overlap:
     * how many are genuinely DLC-new vs base textures that failed to share. */
    {
        char line[256]; int o = 0; LONG dumped = 0;
        for (j = 0; j < (int)KSET_SLOTS; j++) {
            if (g_kset[j] == 0) continue;
            o += wsprintfA(line + o, " %08lX", g_kset[j]);
            dumped++;
            if (o > 200) { pmc_log("cc", "  hkeys:%s", line); o = 0; line[0] = 0; }
        }
        if (o) pmc_log("cc", "  hkeys:%s", line);
        pmc_log("cc", "  (dumped %ld distinct hashes for offline base-overlap)", dumped);
    }
    (void)distinct;
    pmc_log_flush();
}

/* ---- Mtrl_Parse capture: the over-counted material the engine actually reads ----
 * FUN_00858790(__cdecl, p1=material struct, p2=stream{cursor@0x10, base@0x18}) parses
 * a material: 26 dwords + u16 flags@104 + u16 count@106 + count*u32 texture hashes into
 * a FIXED 10-slot array (p1+0x144). count>10 overruns the stream (into param floats) AND
 * the array. On disk every MTRL/SCRB chunk has count<=10, yet the engine reads 17/29 — so
 * the parsed stream is laid out differently. Dump the EXACT source bytes for overrun cases. */
#define FN_858790  0x00858790u
/* CONVENTION (verified from binary disasm): __stdcall. Prologue mov ebx,[ebp+0xc] reads
 * the stream (cursor@0x10, base@0x18) => p2=stream; mov esi,[ebp+0x8] writes material
 * fields => p1=material. Epilogue `ret 0x8` (0x858ee3) => callee cleans => __stdcall. The
 * earlier __cdecl hook double-cleaned the 8 args bytes -> stack-address EIP crash. */
typedef void(__stdcall *fn_858790_t)(void *p1, int p2);
static fn_858790_t g_orig_858790 = NULL;
static volatile LONG g_matdumps = 0;

static void __stdcall Hook_858790(void *p1, int p2)
{
    DWORD base = 0, cur0 = 0, cnt = 0;
    rd4((DWORD)p2 + 0x18, &base);                /* stream base (stable across parse)      */
    rd4((DWORD)p2 + 0x10, &cur0);                /* stream cursor BEFORE parse = material@0 */
    g_orig_858790(p1, p2);                       /* run the real parse                     */
    if (rd4((DWORD)p1 + 0xA2, &cnt)) {
        DWORD count = cnt & 0xFFFFu;             /* engine's PARSED texture count @ p1+0xa2 */
        if (count > 10 && InterlockedIncrement(&g_matdumps) <= 8) {
            DWORD src = base + cur0, off;
            char line[256]; int o = 0;
            pmc_log("mtrl", "OVERCOUNT count=%lu p1=%08lX streambase=%08lX cur0=%lX src(material@0)=%08lX",
                    count, (DWORD)p1, base, cur0, src);
            /* on-wire source bytes (mark flags@104 / count@106 / hashes@108) */
            for (off = 0; off < 0x130; off += 4) {
                DWORD w = 0;
                if (rd4(src + off, &w)) o += wsprintfA(line + o, "%s%08lX",
                        (off == 104 || off == 108) ? (off == 104 ? " [104]" : " [108]") : " ", w);
                else o += wsprintfA(line + o, " ????????");
                if (o > 200) { pmc_log("mtrl", "  src:%s", line); o = 0; line[0] = 0; }
            }
            if (o) pmc_log("mtrl", "  src:%s", line);
            /* parsed material struct: count@0xA2 + the 10-slot {hash,F011157A,0} array@0x144 */
            o = 0; line[0] = 0;
            for (off = 0xA0; off < 0x180; off += 4) {
                DWORD w = 0;
                if (rd4((DWORD)p1 + off, &w)) o += wsprintfA(line + o, "%s%08lX",
                        (off == 0xA0 || off == 0x144) ? (off == 0xA0 ? " [A0]" : " [144]") : " ", w);
                else o += wsprintfA(line + o, " ????????");
                if (o > 200) { pmc_log("mtrl", "  p1:%s", line); o = 0; line[0] = 0; }
            }
            if (o) pmc_log("mtrl", "  p1:%s", line);
            pmc_log_flush();
        }
    }
}

int InstallCcTracer(void)
{
    MH_STATUS st = MH_Initialize();
    if (st != MH_OK && st != MH_ERROR_ALREADY_INITIALIZED) {
        pmc_log("cc", "MH_Initialize failed: %s", MH_StatusToString(st));
        return 0;
    }
    st = MH_CreateHook((LPVOID)FN_CC130, (LPVOID)&Hook_cc130, (LPVOID *)&g_orig_cc130);
    if (st != MH_OK) {
        pmc_log("cc", "MH_CreateHook(0x%08X) failed: %s", FN_CC130, MH_StatusToString(st));
        return 0;
    }
    if (MH_EnableHook((LPVOID)FN_CC130) != MH_OK) {
        pmc_log("cc", "MH_EnableHook failed");
        return 0;
    }
    pmc_log("cc", "texture-component insert tracer ARMED on FUN_004cc130: histograms "
            "the caller of every pool insert + samples keys; dumped at the burst.");
    /* Mtrl_Parse capture (__stdcall, convention verified from disasm: ret 0x8). Dumps the
     * on-wire source bytes + the parsed material struct for any material the engine parses
     * with texture count > 10 (the overrun that floods the texture-component pool). */
    if (MH_CreateHook((LPVOID)FN_858790, (LPVOID)&Hook_858790, (LPVOID *)&g_orig_858790) == MH_OK
        && MH_EnableHook((LPVOID)FN_858790) == MH_OK) {
        pmc_log("mtrl", "Mtrl_Parse capture ARMED on FUN_00858790 (__stdcall): dumps the "
                "first 8 materials parsed with count>10 (src + parsed struct).");
    } else {
        pmc_log("mtrl", "Mtrl_Parse capture FAILED to arm on FUN_00858790.");
    }
    pmc_log_flush();
    return 1;
}
