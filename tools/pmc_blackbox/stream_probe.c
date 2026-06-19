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
#include <tlhelp32.h>

extern void pmc_log(const char *source, const char *fmt, ...);
extern void pmc_log_flush(void);

/* Set to 1 by lua_log_hook.c when "Loading vz level …" is logged — arms the
 * no-progress wedge detector so it only fires during the world load. */
volatile long g_pmc_world_loading = 0;

#define MGR_PTR_SLOT   0x01176630u   /* holds the manager base pointer */
#define POOL_FREE_SLOT 0x016CE8C0u   /* render-instance pool free count (progress proxy) */
#define OFF_PEND_HEAD  0x808u
#define OFF_PEND_CNT   0x814u
#define OFF_INFL_HEAD  0x818u
#define OFF_INFL_CNT   0x824u
#define OFF_LIST3_HEAD 0x828u        /* finalize/upload list: a node parked here */
#define OFF_LIST3_CNT  0x834u        /* holds buffer budget and wedges promotion */

#define POLL_MS        500u
#define STABLE_TICKS   6            /* 6 * 500ms = ~3s static before we trust it */
#define WEDGE_TICKS    16           /* 16 * 500ms = ~8s no-progress during world load */

static int ptr_ok(DWORD p)
{
    return p >= 0x01000000u && p < 0x40000000u;
}

static DWORD rd32(DWORD a)
{
    return *(volatile DWORD *)a;
}

/* Hexdump up to `n` bytes (as dwords) at `p`, VirtualQuery-gated so a bad/garbage
 * pointer never faults the watchdog. Used to dump the node descriptor (node+0x38)
 * and the read buffer (node+0x60) — the buffer holds the asset's on-disk UCFX
 * header (magic + type hash + name), which NAMES the stuck asset post-mortem. */
static void dump_mem(DWORD p, DWORD n, const char *label)
{
    MEMORY_BASIC_INFORMATION mbi;
    DWORD region_end, avail, k;
    char line[200];
    int off;
    const DWORD *w;

    if (p < 0x00010000u) { pmc_log("stall", "    %s=%08lX (null/low)", label, p); return; }
    if (VirtualQuery((LPCVOID)p, &mbi, sizeof(mbi)) != sizeof(mbi) || mbi.State != MEM_COMMIT ||
        !(mbi.Protect & (PAGE_READONLY | PAGE_READWRITE | PAGE_WRITECOPY |
                         PAGE_EXECUTE_READ | PAGE_EXECUTE_READWRITE))) {
        pmc_log("stall", "    %s=%08lX (unreadable)", label, p);
        return;
    }
    region_end = (DWORD)mbi.BaseAddress + (DWORD)mbi.RegionSize;
    avail = region_end - p;
    if (n > avail) n = avail;
    if (n > 64) n = 64;
    w = (const DWORD *)p;
    off = wsprintfA(line, "    %s @%08lX:", label, p);
    for (k = 0; k + 4 <= n; k += 4)
        off += wsprintfA(line + off, " %08lX", w[k / 4]);
    pmc_log("stall", "%s", line);
}

/* Deep dump for a single blocker node (in-flight / list3): the extended fields
 * FUN_00875c00 keys completion on (+0x0c count, +0x14 sub-array, +0x20/+0x24
 * outstanding-op counters — if +0x20!=0 the node resets st35 every tick and never
 * drains), plus the descriptor (+0x38) and read buffer (+0x60) to name the asset. */
static void dump_node_deep(DWORD node, const char *tag)
{
    const DWORD *n = (const DWORD *)node;
    if (!ptr_ok(node)) return;
    pmc_log("stall",
        "    [%s deep] +08=%08lX +0c=%08lX +10=%08lX +14=%08lX +18=%08lX "
        "+20=%08lX +24=%08lX +28=%08lX +2c=%08lX +30=%08lX +38=%08lX",
        tag, n[0x08 / 4], n[0x0c / 4], n[0x10 / 4], n[0x14 / 4], n[0x18 / 4],
        n[0x20 / 4], n[0x24 / 4], n[0x28 / 4], n[0x2c / 4], n[0x30 / 4], n[0x38 / 4]);
    dump_mem(n[0x38 / 4], 64, "desc(+38)");   /* descriptor: asset hash/page-count */
    dump_mem(n[0x60 / 4], 64, "buf(+60)");    /* read buffer: UCFX header / name   */
}

static void dump_node_deep(DWORD node, const char *tag);

/* Walk one of the manager's intrusive node lists and log every node. `head_off`
 * is the sentinel offset, `cnt_off` its count; `tag` labels the list. `deep`
 * adds the extended-field + descriptor + buffer dump per node (use only for the
 * small in-flight / list3 blocker lists, NOT the 15+ pending victims). */
static void dump_list(DWORD mgr, DWORD head_off, DWORD cnt_off, const char *tag, int deep)
{
    DWORD count    = rd32(mgr + cnt_off);
    DWORD sentinel = mgr + head_off;
    DWORD node     = rd32(sentinel);
    int i;

    pmc_log("stall", "  --- %s list: count=%lu (sentinel=%08lX) ---", tag, count, sentinel);
    for (i = 0; i < (int)count && i < 64; i++) {
        const unsigned char *nb;
        const DWORD *n;
        if (!ptr_ok(node) || node == sentinel)
            break;
        nb = (const unsigned char *)node;
        n  = (const DWORD *)node;
        pmc_log("stall",
            "  [%s %02d] node=%08lX file=%08lX eidx=%04X off40=%08lX a44=%08lX "
            "size48=%08lX ALLOC4c=%08lX buf60=%08lX st34=%02X st35=%02X fl36=%02X "
            "lvl5a=%04X needsz50=%08lX",
            tag, i, node, n[0x3c / 4], *(const unsigned short *)(nb + 0x58),
            n[0x40 / 4], n[0x44 / 4], n[0x48 / 4], n[0x4c / 4], n[0x60 / 4],
            nb[0x34], nb[0x35], nb[0x36], *(const unsigned short *)(nb + 0x5a),
            n[0x50 / 4]);
        if (deep)
            dump_node_deep(node, tag);
        node = rd32(node + 0x00);   /* next */
    }
}

static void dump_pending(DWORD mgr)
{
    pmc_log("stall", "WEDGE pending dump: mgr=%08lX pending=%lu in-flight=%lu list3=%lu",
            mgr, rd32(mgr + OFF_PEND_CNT), rd32(mgr + OFF_INFL_CNT),
            rd32(mgr + OFF_LIST3_CNT));

    /* Budget accounting — confirms whether the buffer POOL is exhausted (every
     * pending node has buf60=0, i.e. allocation never happened). FUN_00872e60 uses
     * a 0x3FFC0000 (~1GB) ceiling against `used` @+0x4c36c; FUN_00875b00 then allocs
     * node+0x4c only if it fits FUN_0084d630()'s free pool. If `used` is near the
     * ceiling with only ~392 resident textures, the buffers are over-sized (the
     * page-count/ALLOC4c corruption) and the pool is exhausted. */
    {
        DWORD used  = rd32(mgr + 0x4c36c);
        DWORD bud50 = rd32(mgr + 0x4c350);
        DWORD cap58 = rd32(mgr + 0x4c358);
        DWORD avail = used <= 0x3ffc0000u ? 0x3ffc0000u - used : 0;
        pmc_log("stall",
            "  BUDGET used(+4c36c)=%08lX avail=%08lX ceil=3FFC0000 "
            "bufbud(+4c350)=%08lX maxconc(+4c358)=%08lX flag359=%02X blk35b=%02X "
            "resident=%lu list3=%lu",
            used, avail, bud50, cap58,
            *(const unsigned char *)(mgr + 0x4c359),
            *(const unsigned char *)(mgr + 0x4c35b),
            rd32(mgr + 0x844), rd32(mgr + 0x834));
    }

    /* The pending nodes are VICTIMS of the gate. The node ACTUALLY wedging the
     * queue is in list3 (finalize/upload): it holds buffer budget so the tick's
     * promotion gate (in-flight+list3 buffer must be <= bufbud, and bufbud=0) can
     * never let a pending node through. Dump in-flight + list3 so the real blocker
     * is named, not just its victims. */
    dump_list(mgr, OFF_INFL_HEAD,  OFF_INFL_CNT,  "INFL", 1);
    dump_list(mgr, OFF_LIST3_HEAD, OFF_LIST3_CNT, "LST3", 1);
    dump_list(mgr, OFF_PEND_HEAD,  OFF_PEND_CNT,  "PEND", 0);
    pmc_log_flush();
}

/* Capture each thread's call stack (exe-range return addresses) — names WHERE the
 * main thread is parked during a wedge. To avoid deadlocking on the log lock, we
 * suspend a thread, snapshot its stack into a local buffer, RESUME it, and only THEN
 * log. Read-only, VirtualQuery-gated (a thread whose stack page is decommitted is
 * skipped). The parked main thread shows return addresses into the level-load /
 * streaming code (0x47xxxx / 0x87xxxx), which is the wedge lead. */
static void dump_thread_stacks(void)
{
    DWORD myTid = GetCurrentThreadId();
    DWORD myPid = GetCurrentProcessId();
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
    THREADENTRY32 te;
    if (snap == INVALID_HANDLE_VALUE) return;
    te.dwSize = sizeof(te);
    if (!Thread32First(snap, &te)) { CloseHandle(snap); return; }
    do {
        DWORD found[40]; int nfound = 0;
        DWORD eip = 0, esp = 0, ebp = 0;
        HANDLE th;
        if (te.th32OwnerProcessID != myPid || te.th32ThreadID == myTid) continue;
        th = OpenThread(THREAD_SUSPEND_RESUME | THREAD_GET_CONTEXT | THREAD_QUERY_INFORMATION,
                        FALSE, te.th32ThreadID);
        if (!th) continue;
        if (SuspendThread(th) != (DWORD)-1) {
            CONTEXT ctx;
            ctx.ContextFlags = CONTEXT_CONTROL | CONTEXT_INTEGER;
            if (GetThreadContext(th, &ctx)) {
                MEMORY_BASIC_INFORMATION mbi;
                eip = ctx.Eip; esp = ctx.Esp; ebp = ctx.Ebp;
                if (esp >= 0x00010000u &&
                    VirtualQuery((LPCVOID)esp, &mbi, sizeof mbi) == sizeof mbi &&
                    mbi.State == MEM_COMMIT) {
                    DWORD region_end = (DWORD)mbi.BaseAddress + (DWORD)mbi.RegionSize;
                    DWORD limit = esp + 0x1000u, a;
                    if (limit > region_end) limit = region_end;
                    for (a = esp; a + 4 <= limit && nfound < 40; a += 4) {
                        DWORD v = *(const DWORD *)a;
                        if (v >= 0x00401000u && v < 0x00C00000u) found[nfound++] = v;
                    }
                }
            }
            ResumeThread(th);     /* resume BEFORE logging (log lock may be held here) */
        }
        CloseHandle(th);
        if (eip || nfound) {
            char line[240]; int o, k;
            pmc_log("stall", "  thr %lu: EIP=%08lX ESP=%08lX EBP=%08lX (%d exe frames)",
                    te.th32ThreadID, eip, esp, ebp, nfound);
            o = wsprintfA(line, "    stk:");
            for (k = 0; k < nfound; k++) {
                o += wsprintfA(line + o, " %08lX", found[k]);
                if (o > 200) { pmc_log("stall", "%s", line); o = wsprintfA(line, "    stk:"); }
            }
            if (nfound) pmc_log("stall", "%s", line);
        }
    } while (Thread32Next(snap, &te));
    CloseHandle(snap);
}

/* One-shot dump for a no-progress world-load wedge: the streaming manager state (if
 * the ptr is valid) plus every thread's stack. */
static void dump_wedge(DWORD mgr)
{
    pmc_log("stall", "==== WORLD-LOAD WEDGE: no progress for ~%us after 'Loading vz level' ====",
            (WEDGE_TICKS * POLL_MS) / 1000u);
    if (ptr_ok(mgr)) {
        dump_pending(mgr);
    } else {
        pmc_log("stall", "  streaming mgr @%08X = %08lX (not a valid mgr — wedge is upstream of streaming)",
                MGR_PTR_SLOT, rd32(MGR_PTR_SLOT));
    }
    pmc_log("stall", "  -- thread stacks (find the parked main thread: 0x47xxxx level-load / 0x87xxxx streaming) --");
    dump_thread_stacks();
    pmc_log_flush();
}

static DWORD WINAPI WatchdogThread(LPVOID arg)
{
    DWORD last_pend = 0xFFFFFFFFu;
    int   stable = 0;
    int   dumped = 0;
    /* no-progress wedge detector (world-load gated) */
    DWORD last_sig = 0xFFFFFFFFu;
    int   noprog = 0, wedged = 0;
    (void)arg;

    for (;;) {
        DWORD mgr;
        Sleep(POLL_MS);
        mgr = rd32(MGR_PTR_SLOT);

        /* (1) original pending-backed-up one-shot (pend>0, in-flight==0, stable) */
        if (!dumped && ptr_ok(mgr)) {
            DWORD pend = rd32(mgr + OFF_PEND_CNT);
            DWORD infl = rd32(mgr + OFF_INFL_CNT);
            if (pend > 0 && pend < 1000 && infl == 0 && pend == last_pend) {
                if (++stable >= STABLE_TICKS) { dump_pending(mgr); dumped = 1; }
            } else { stable = 0; last_pend = pend; }
        }

        /* (2) no-progress wedge detector — fires for IN-FLIGHT-stuck and idle-blocked
         *     wedges the pending-only check (1) misses (it requires infl==0). Gated to
         *     the world load. Progress = any change in pool-free / pending / in-flight. */
        if (!wedged && g_pmc_world_loading) {
            DWORD pf = 0, p = 0, in = 0, sig;
            MEMORY_BASIC_INFORMATION mbi;
            if (VirtualQuery((LPCVOID)POOL_FREE_SLOT, &mbi, sizeof mbi) == sizeof mbi &&
                mbi.State == MEM_COMMIT)
                pf = rd32(POOL_FREE_SLOT);
            if (ptr_ok(mgr)) { p = rd32(mgr + OFF_PEND_CNT); in = rd32(mgr + OFF_INFL_CNT); }
            sig = pf ^ (p << 1) ^ (in << 17);
            if (sig == last_sig) {
                if (++noprog >= WEDGE_TICKS) { dump_wedge(mgr); wedged = 1; }
            } else { noprog = 0; last_sig = sig; }
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
