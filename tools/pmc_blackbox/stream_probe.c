/**
 * stream_probe.c — streaming-stall watchdog.
 *
 * Names the resources that wedge world-load streaming. An earlier version hooked
 * the promotion gate (FUN_00872db0), but that gate is NOT hammered during the
 * wedge: the manager attempts a node, the budget check (FUN_00872e60) blocks it,
 * and then it simply waits — so a per-call hook captures nothing. Instead this
 * runs a tiny background thread that POLLS the streaming manager's queue and,
 * once the queue has been stuck (pending>0, in-flight==0, count unchanged) for a
 * few seconds, walks the pending list ONCE and logs every stuck node.
 *
 * Why this is safe:
 *   - No engine detour, no hot path — just a 500 ms poll on its own thread.
 *   - It only reads. It dereferences the pending list ONLY after the queue has
 *     been static for ~3 s, so the list isn't being mutated under it.
 *   - Every pointer is range-checked before use; the walk is bounded (<=64).
 *   - One-shot: it dumps once, then idles.
 *
 * Streaming manager layout (from the decompiled gate / budget / read fns):
 *   [0x01176630]            -> manager base (mgr)
 *   mgr+0x808  pending list head sentinel   mgr+0x814  pending count
 *   mgr+0x818  in-flight list head          mgr+0x824  in-flight count
 * Pending node (intrusive doubly-linked, next@+0x00 / prev@+0x04):
 *   +0x3c file id   +0x40/44/48 read off/size args   +0x4c ALLOC size
 *   +0x50 required size   +0x58 entry idx   +0x5a level   +0x60 buffer
 *   +0x34/35/36 status / flags bytes
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

extern void pmc_log(const char *source, const char *fmt, ...);
extern void pmc_log_flush(void);

#define MGR_PTR_SLOT   0x01176630u   /* holds the manager base pointer */
#define OFF_PEND_HEAD  0x808u
#define OFF_PEND_CNT   0x814u
#define OFF_INFL_CNT   0x824u

#define POLL_MS        500u
#define STABLE_TICKS   6            /* 6 * 500ms = ~3s static before we trust it */

static int ptr_ok(DWORD p)
{
    return p >= 0x01000000u && p < 0x40000000u;
}

static DWORD rd32(DWORD a)
{
    return *(volatile DWORD *)a;
}

static void dump_pending(DWORD mgr)
{
    DWORD count    = rd32(mgr + OFF_PEND_CNT);
    DWORD sentinel = mgr + OFF_PEND_HEAD;
    DWORD node     = rd32(sentinel);
    int i;

    pmc_log("stall", "WEDGE pending dump: mgr=%08lX pending=%lu in-flight=%lu",
            mgr, count, rd32(mgr + OFF_INFL_CNT));

    for (i = 0; i < (int)count && i < 64; i++) {
        const unsigned char *nb;
        const DWORD *n;
        if (!ptr_ok(node) || node == sentinel)
            break;
        nb = (const unsigned char *)node;
        n  = (const DWORD *)node;
        pmc_log("stall",
            "  [%02d] node=%08lX file=%08lX eidx=%04X off40=%08lX a44=%08lX "
            "size48=%08lX ALLOC4c=%08lX buf60=%08lX st34=%02X st35=%02X fl36=%02X "
            "lvl5a=%04X needsz50=%08lX",
            i, node, n[0x3c / 4], *(const unsigned short *)(nb + 0x58),
            n[0x40 / 4], n[0x44 / 4], n[0x48 / 4], n[0x4c / 4], n[0x60 / 4],
            nb[0x34], nb[0x35], nb[0x36], *(const unsigned short *)(nb + 0x5a),
            n[0x50 / 4]);
        node = rd32(node + 0x00);   /* next */
    }
    pmc_log_flush();
}

static DWORD WINAPI WatchdogThread(LPVOID arg)
{
    DWORD last_pend = 0xFFFFFFFFu;
    int   stable = 0;
    int   dumped = 0;
    (void)arg;

    for (;;) {
        DWORD mgr, pend, infl;
        Sleep(POLL_MS);
        if (dumped)
            continue;                       /* one-shot done; idle */

        mgr = rd32(MGR_PTR_SLOT);
        if (!ptr_ok(mgr)) { stable = 0; continue; }

        pend = rd32(mgr + OFF_PEND_CNT);
        infl = rd32(mgr + OFF_INFL_CNT);

        if (pend > 0 && pend < 1000 && infl == 0 && pend == last_pend) {
            if (++stable >= STABLE_TICKS) {
                dump_pending(mgr);
                dumped = 1;
            }
        } else {
            stable = 0;
            last_pend = pend;
        }
    }
    return 0;
}

int InstallStreamProbe(void)
{
    HANDLE h = CreateThread(NULL, 0, WatchdogThread, NULL, 0, NULL);
    if (h)
        CloseHandle(h);
    pmc_log("stall", "Streaming-stall watchdog started (polls mgr @[0x%08X] every "
            "%ums; dumps the pending queue once it's been stuck >=%us). Source [stall].",
            MGR_PTR_SLOT, POLL_MS, (STABLE_TICKS * POLL_MS) / 1000u);
    pmc_log_flush();
    return 1;
}
