/**
 * crash_handler.c — capture the faulting site when the game dies.
 *
 * The retail EXE has no usable unhandled-exception path: on a fault the process
 * just vanishes, leaving no record of WHERE it crashed. This installs two nets so
 * any fatal fault is written to pmc_blackbox.log (source [crash]) before the
 * process goes down — the faulting EIP, the exception code, the AV target
 * address, the full integer register file, and the exe-range return addresses on
 * the stack (a poor-man's call stack).
 *
 *   - A Vectored Exception Handler catches the fault FIRST-chance (before any
 *     frame SEH), so it fires even if something later swallows the exception.
 *   - SetUnhandledExceptionFilter catches the classic last-chance fatal path.
 *
 * Safe by construction: faulting EIPs are de-duplicated (a repeating fault logs
 * once), a reentrancy guard prevents recursion if logging itself faults, and the
 * stack walk is skipped for stack-overflow exceptions (where touching the stack
 * would re-fault). Only "severe" codes are logged via the VEH so ordinary
 * first-chance noise is ignored.
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

extern void pmc_log(const char *source, const char *fmt, ...);
extern void pmc_log_flush(void);
extern void prmg_bw_report_element(DWORD edi);       /* prmg_build_watch.c */
extern void prmg_bw_diagnose_renderable(DWORD thiz); /* prmg_build_watch.c */
extern void cc_tracer_dump(const char *why);         /* cc_tracer.c */

/* Heap-history tracker (heap_guard.c): on a fault, correlate a corrupted address
 * against the alloc/free ring to reveal use-after-free / overflow + the caller.
 * Weak so a control build without heap_guard.c still links (no-op then). */
void HeapGuardQuery(DWORD addr) __attribute__((weak));

#define CRASH_SEEN_N    32
#define CRASH_REARM_MS  2000     /* re-log a recurring EIP after this gap */
static DWORD g_seen[CRASH_SEEN_N];
static DWORD g_seenTick[CRASH_SEEN_N];
static int   g_seenCount;
static LONG  g_inHandler;            /* reentrancy guard */

/* Return 1 if this faulting EIP should be SUPPRESSED right now. A site is logged
 * on first sight and re-logged once CRASH_REARM_MS has elapsed since its last
 * log — so a fault that is HANDLED first-chance and then recurs FATALLY later is
 * not hidden forever (the old permanent dedup dropped the killing blow). The
 * fatal/last-chance path bypasses this entirely (see log_exception `force`). */
static int crash_suppress(DWORD addr)
{
    DWORD now = GetTickCount();
    int i;
    for (i = 0; i < g_seenCount; i++) {
        if (g_seen[i] == addr) {
            if (now - g_seenTick[i] < CRASH_REARM_MS)
                return 1;
            g_seenTick[i] = now;
            return 0;
        }
    }
    if (g_seenCount < CRASH_SEEN_N) {
        g_seen[g_seenCount]     = addr;
        g_seenTick[g_seenCount] = now;
        g_seenCount++;
    }
    return 0;
}

static int is_severe(DWORD code)
{
    switch (code) {
    case EXCEPTION_ACCESS_VIOLATION:
    case EXCEPTION_ILLEGAL_INSTRUCTION:
    case EXCEPTION_PRIV_INSTRUCTION:
    case EXCEPTION_STACK_OVERFLOW:
    case EXCEPTION_ARRAY_BOUNDS_EXCEEDED:
    case EXCEPTION_INT_DIVIDE_BY_ZERO:
    case EXCEPTION_IN_PAGE_ERROR:
    case 0xC0000409UL:              /* __fastfail / stack-cookie */
        return 1;
    default:
        return 0;
    }
}

/* The engine Entity vtable (mercs2_annotations: Entity_Destruct @0x790170).
 * The world-load type-confusion crash (0x7939C0 / FUN_007938C0 entity dispatch)
 * derefs entity+0x188 — a handler/delegate that is non-NULL but ZEROED (its
 * +0x10 vtable is NULL). When any GP register at a crash points to an Entity
 * (its first dword == this vtable), post-mortem it below to NAME the culprit. */
#define ENTITY_VTABLE 0x00BDB410UL

/* How many bytes at `p` are safely committed+readable (0 if none). */
static DWORD safe_avail(DWORD p)
{
    MEMORY_BASIC_INFORMATION mbi;
    if (p < 0x00010000UL) return 0;
    if (VirtualQuery((LPCVOID)p, &mbi, sizeof(mbi)) != sizeof(mbi)) return 0;
    if (mbi.State != MEM_COMMIT) return 0;
    if (!(mbi.Protect & (PAGE_READONLY | PAGE_READWRITE | PAGE_WRITECOPY |
                         PAGE_EXECUTE_READ | PAGE_EXECUTE_READWRITE)))
        return 0;
    return ((DWORD)mbi.BaseAddress + (DWORD)mbi.RegionSize) - p;
}

/* Hexdump up to `n` bytes (dwords) at `p`, VirtualQuery-gated. */
static void dump_at(DWORD p, DWORD n, const char *label)
{
    DWORD avail = safe_avail(p), k;
    const DWORD *w = (const DWORD *)p;
    char line[256];
    int off;
    if (!avail) { pmc_log("crash", "  %s @%08lX: (unreadable)", label, p); return; }
    if (n > avail) n = avail;
    if (n > 96) n = 96;
    off = wsprintfA(line, "  %s @%08lX:", label, p);
    for (k = 0; k + 4 <= n; k += 4)
        off += wsprintfA(line + off, " %08lX", w[k / 4]);
    pmc_log("crash", "%s", line);
}

/* Scan `n` bytes at `p` for printable ASCII runs (>=4 chars) and log them —
 * surfaces entity/component name strings (e.g. "vz_...", "Road 0x...") that
 * identify which entity carries the corrupt handler. VirtualQuery-gated. */
static void scan_ascii(DWORD p, DWORD n, const char *label)
{
    DWORD avail = safe_avail(p), i, runlen = 0;
    const unsigned char *b = (const unsigned char *)p;
    char run[80];
    if (!avail) return;
    if (n > avail) n = avail;
    if (n > 512) n = 512;
    for (i = 0; i <= n; i++) {
        unsigned char c = (i < n) ? b[i] : 0;
        if (c >= 0x20 && c < 0x7F && runlen < sizeof(run) - 1) {
            run[runlen++] = (char)c;
        } else {
            if (runlen >= 4) {
                run[runlen] = 0;
                pmc_log("crash", "  %s str@%08lX: \"%s\"", label, p + i - runlen, run);
            }
            runlen = 0;
        }
    }
}

/* Post-mortem an Entity (vtable 0xBDB410) at `ent`: dump its header, the
 * +0x188 handler (the crash target), the +0x28/+0xA0 component containers, and
 * scan all of them for name strings. Read-only, fully VQ-gated. */
static void dump_entity(DWORD ent)
{
    DWORD handler, cont28, contA0, descr;
    pmc_log("crash", "  --- ENTITY post-mortem @%08lX (vtable 0xBDB410) ---", ent);
    dump_at(ent + 0x00, 0x60, "ent+00");
    dump_at(ent + 0x180, 0x20, "ent+180");   /* covers +0x188 handler ptr */
    handler = (safe_avail(ent + 0x188) >= 4) ? *(const DWORD *)(ent + 0x188) : 0;
    pmc_log("crash", "  ent+0x188 (handler) = %08lX", handler);
    if (handler) {
        dump_at(handler, 0x40, "handler");
        scan_ascii(handler, 0x40, "handler");
    }
    /* Heap forensics: who allocated the entity and what's really at the handler
     * slot (live block / use-after-free / overflow neighbor). */
    if (HeapGuardQuery) {
        HeapGuardQuery(ent);
        if (handler) HeapGuardQuery(handler);
    }
    cont28 = (safe_avail(ent + 0x28) >= 4) ? *(const DWORD *)(ent + 0x28) : 0;
    contA0 = (safe_avail(ent + 0xA0) >= 4) ? *(const DWORD *)(ent + 0xA0) : 0;
    descr  = (safe_avail(ent + 0x08) >= 4) ? *(const DWORD *)(ent + 0x08) : 0;
    if (cont28) dump_at(cont28, 0x60, "comp+28");
    if (contA0) dump_at(contA0, 0x60, "comp+A0");
    if (descr)  { dump_at(descr, 0x40, "descr+08"); scan_ascii(descr, 0x80, "descr"); }
    scan_ascii(ent, 0x200, "ent");
    if (cont28) scan_ascii(cont28, 0x100, "comp28");
    if (contA0) scan_ascii(contA0, 0x100, "compA0");
}

/* The 0x4AB26B world-population crash: a model-segment substructure walk.
 *   ecx = [param+0x1e0]+0x28 + idx*0x3c        (param @ [esp+0x1c])
 *   ebp = [ecx+4]                              (segment record, VALID)
 *   esi = [ebp+0x2c] + ecx_index               (+0x2c holds int 3, NOT a ptr)
 *   cmp word[esi+0xc] -> AV.
 * The faulting function is UNLABELED in Ghidra (0x4ab19a..0x4ab380 gap). param,
 * the model, and the segment are all reachable here read-only — name the asset
 * post-mortem instead of a (too-hot-to-set) breakpoint. ebp+0x28 carries a valid
 * pointer beside the bogus +0x2c=3, so dump its target too (suspected real array
 * / transposed {ptr,count} pair). */
#define SPAWN_WALK_LO 0x004AB1A0UL
#define SPAWN_WALK_HI 0x004AB380UL

static void dump_spawn_walk(CONTEXT *cx)
{
    DWORD esp = cx->Esp, ebp = cx->Ebp;
    DWORD param, model, ptr28;
    pmc_log("crash", "  --- 0x4AB26B model-segment spawn-walk post-mortem ---");
    /* param @ [esp+0x1c] (used by the fn as [param+0x1e0]) */
    param = (safe_avail(esp + 0x1c) >= 4) ? *(const DWORD *)(esp + 0x1c) : 0;
    pmc_log("crash", "  param([esp+1C]) = %08lX", param);
    if (param) {
        DWORD idx, contA0, rec;
        dump_at(param + 0x00, 0x40, "param+00");
        dump_at(param + 0x1c0, 0x60, "param+1C0");   /* covers +0x1e0 model + +0x1e4 index */
        scan_ascii(param, 0x200, "param");
        if (safe_avail(param) >= 4 && *(const DWORD *)param == ENTITY_VTABLE)
            dump_entity(param);
        /* component container @ +0xA0 (the 0x7E045E type-confusion site) */
        contA0 = (safe_avail(param + 0xA0) >= 4) ? *(const DWORD *)(param + 0xA0) : 0;
        pmc_log("crash", "  param+0xA0 (comp container) = %08lX", contA0);
        if (contA0) { dump_at(contA0, 0x40, "compA0"); scan_ascii(contA0, 0x80, "compA0"); }
        idx = (safe_avail(param + 0x1e4) >= 4) ? *(const DWORD *)(param + 0x1e4) : 0;
        model = (safe_avail(param + 0x1e0) >= 4) ? *(const DWORD *)(param + 0x1e0) : 0;
        pmc_log("crash", "  model([param+1E0]) = %08lX  idx([param+1E4]) = %08lX", model, idx);
        if (model) {
            dump_at(model + 0x00, 0x60, "model+00");
            scan_ascii(model, 0x200, "model");
            /* the engine record: rec = [model+0x28] base + idx*0x3c; ebp = [rec+4] */
            if (safe_avail(model + 0x28) >= 4) {
                DWORD base = *(const DWORD *)(model + 0x28);
                pmc_log("crash", "  model+0x28 (rec array base) = %08lX", base);
                if (base) {
                    rec = base + idx * 0x3c;
                    pmc_log("crash", "  rec = base + idx*0x3c = %08lX", rec);
                    dump_at(rec, 0x3c, "rec");
                }
            }
            if (HeapGuardQuery) HeapGuardQuery(model);
        }
    }
    /* segment record (ebp) + the valid +0x28 pointer next to the bad +0x2c=3 */
    dump_at(ebp, 0x40, "segm(ebp)");
    scan_ascii(ebp, 0x80, "segm");
    ptr28 = (safe_avail(ebp + 0x28) >= 4) ? *(const DWORD *)(ebp + 0x28) : 0;
    pmc_log("crash", "  segm+0x28 (valid ptr?) = %08lX   segm+0x2C (bad) = %08lX",
            ptr28, (safe_avail(ebp + 0x2c) >= 4) ? *(const DWORD *)(ebp + 0x2c) : 0);
    if (ptr28) { dump_at(ptr28, 0x60, "segm+28*"); scan_ascii(ptr28, 0x100, "segm+28*"); }
    if (HeapGuardQuery) HeapGuardQuery(ebp);
}

/* PRMG render-resource registry probe (the 0x47AA5C / 0x47A7D8 / 0x47A6FB family).
 * FUN_00478270 resolves two render-resource handles per primitive group from a
 * 256-slot parallel hash table: keys @0x197de48, handles @0x197da48 (sentinel
 * 0x197da44). A lookup MISS stores NULL (record+4=0 here); a stale/foreign handle
 * faults at [handle+0xfc] (record+0=0x08270420 here). This dumps what is actually
 * registered, reverse-resolves the faulting handle to its key, and classifies it
 * — so we can tell converter-mangled key vs unregistered resource vs stale handle.
 * Read-only, VirtualQuery-gated. */
#define PRMG_KEYTAB  0x0197DE48UL
#define PRMG_HNDTAB  0x0197DA48UL
static void dump_prmg_registry(CONTEXT *cx)
{
    DWORD elem = cx->Edi;          /* the 0x1c4-stride primitive-group element */
    DWORD rec0 = cx->Ebx;          /* record+0 handle (faulting deref [rec0+0xfc]) */
    DWORD rec4 = (safe_avail(elem + 8) >= 4) ? *(const DWORD *)(elem + 4) : 0xFFFFFFFFUL;
    const DWORD *keys = (const DWORD *)PRMG_KEYTAB;
    const DWORD *hnds = (const DWORD *)PRMG_HNDTAB;
    int i, nreg = 0, slot0 = -1;
    char line[256];
    int off;
    if (safe_avail(PRMG_KEYTAB) < 256 * 4 || safe_avail(PRMG_HNDTAB) < 256 * 4) {
        pmc_log("crash", "  [prmg-reg] tables unreadable");
        return;
    }
    for (i = 0; i < 256; i++) {
        if (keys[i] != 0) nreg++;
        if (rec0 != 0 && hnds[i] == rec0) slot0 = i;
    }
    pmc_log("crash", "  [prmg-reg] %d/256 keys registered; rec0=%08lX rec4=%08lX elem=%08lX",
            nreg, rec0, rec4, elem);
    if (slot0 >= 0)
        pmc_log("crash", "  [prmg-reg] rec0 handle = registry slot %d, KEY=%08lX (record+0 lookup key)",
                slot0, keys[slot0]);
    else
        pmc_log("crash", "  [prmg-reg] rec0=%08lX is NOT in the handle table (foreign/stale ptr)", rec0);
    dump_at(rec0, 0x20, "rec0-target");   /* what the faulting handle points at */
    /* Dump every registered (slot:key>handle) compactly so the full key set is
     * visible for offline rainbow-table resolution + base-vs-DLC diff. */
    off = 0; line[0] = 0;
    for (i = 0; i < 256; i++) {
        if (keys[i] == 0) continue;
        off += wsprintfA(line + off, " [%3d]%08lX>%08lX", i, keys[i], hnds[i]);
        if (off > 170) { pmc_log("crash", "  [prmg-reg]%s", line); off = 0; line[0] = 0; }
    }
    if (off) pmc_log("crash", "  [prmg-reg]%s", line);
    /* DISASM-VERIFIED record layout for the FUN_0047aa20 draw family: the faulting
     * deref is `cmp [ebx+0xfc],0` with EBX = record+4 (the NULL resource handle), and
     * the 0x1c4-stride record itself is at EBP (NOT EDI, which is arg0=the batch). So
     * the asset-identifying field is record+0 (the geometry descriptor, e.g. 0x08270420
     * here = loaded fine) — record+4 from the INFO sub-chunk is what resolved to NULL.
     * Dump the descriptor + record to name the binding-prop asset. */
    {
        DWORD rec = cx->Ebp;
        DWORD r0 = (safe_avail(rec) >= 4)     ? *(const DWORD *)rec       : 0;
        DWORD r4 = (safe_avail(rec + 8) >= 4) ? *(const DWORD *)(rec + 4) : 0;
        pmc_log("crash", "  [prmg-rec] record@EBP=%08lX record+0=%08lX record+4=%08lX (record+4=NULL handle)",
                rec, r0, r4);
        dump_at(r0, 0x80, "record+0 (geom descriptor)");  /* should carry the asset hash/name */
        dump_at(rec, 0x60, "record@EBP");                 /* the full 0x1c4 record head     */
        /* if the descriptor at record+0 carries a vtable, deref it one level for the name */
        if (r0 >= 0x00010000UL && safe_avail(r0) >= 4) {
            DWORD vt = *(const DWORD *)r0;
            dump_at(vt, 0x20, "record+0->vtable");
        }
    }
    /* Build-vs-render compare: was this element clean when FUN_00478120 built it? */
    prmg_bw_report_element(elem);
    /* Classify the record+4 miss from the persisted INFO keys (EDI = renderable). */
    prmg_bw_diagnose_renderable(cx->Edi);
    /* Insert histogram up to this point — attributes the pool drain even on a
     * render-crash run (no pool BURST needed): one dominant caller = inflation,
     * spread across callers = capacity. */
    cc_tracer_dump("render-crash");
}

static void log_exception(EXCEPTION_POINTERS *ep, const char *via, int force)
{
    EXCEPTION_RECORD *er = ep->ExceptionRecord;
    CONTEXT *cx = ep->ContextRecord;
    DWORD eip = (DWORD)(ULONG_PTR)er->ExceptionAddress;

    if (InterlockedExchange(&g_inHandler, 1))   /* logging itself faulted */
        return;
    /* `force` (the fatal/last-chance path) ALWAYS logs; first-chance is throttled
     * per-EIP so a handled fault that later recurs fatally is still captured. */
    if (!force && crash_suppress(eip)) {
        InterlockedExchange(&g_inHandler, 0);
        return;
    }

    pmc_log("crash", "==== %s EXCEPTION %08lX @ EIP=%08lX (flags=%lX) ====",
            via, er->ExceptionCode, eip, er->ExceptionFlags);
    if (er->ExceptionCode == EXCEPTION_ACCESS_VIOLATION && er->NumberParameters >= 2) {
        DWORD kind = (DWORD)er->ExceptionInformation[0];
        pmc_log("crash", "  AV %s target=%08lX",
                kind == 1 ? "WRITE" : kind == 8 ? "EXEC" : "READ",
                (DWORD)er->ExceptionInformation[1]);
    }
    pmc_log("crash", "  EAX=%08lX ECX=%08lX EDX=%08lX EBX=%08lX",
            cx->Eax, cx->Ecx, cx->Edx, cx->Ebx);
    pmc_log("crash", "  ESP=%08lX EBP=%08lX ESI=%08lX EDI=%08lX",
            cx->Esp, cx->Ebp, cx->Esi, cx->Edi);

    /* Shallow stack walk: exe-range return addresses just above ESP. Skipped on
     * stack overflow, where reading the stack would re-fault on the guard page. */
    if (er->ExceptionCode != EXCEPTION_STACK_OVERFLOW) {
        const DWORD *sp = (const DWORD *)cx->Esp;
        int i, found = 0;
        for (i = 0; i < 160 && found < 16; i++) {
            DWORD v = sp[i];
            if (v >= 0x00401000UL && v < 0x00C00000UL) {
                pmc_log("crash", "  stk+%03X = %08lX", i * 4, v);
                found++;
            }
        }
    }

    /* Dump a window of memory at each GP register that looks like a heap/data
     * pointer. For the world-load texture-handle crash (AV reading the 0xF011157A
     * "texture" sentinel) the engine is walking a {hash, 0xF011157A, 0} record
     * array; dumping the structure at EDI/ESI/EAX/etc. captures the asset HASH
     * next to the sentinel, naming the exact unresolved texture post-mortem.
     * VirtualQuery-gated so a bad pointer never re-faults the handler. */
    {
        const DWORD regs[7] = { cx->Eax, cx->Ecx, cx->Edx, cx->Ebx,
                                cx->Esi, cx->Edi, cx->Ebp };
        const char *names[7] = { "EAX", "ECX", "EDX", "EBX", "ESI", "EDI", "EBP" };
        int r;
        for (r = 0; r < 7; r++) {
            DWORD p = regs[r];
            MEMORY_BASIC_INFORMATION mbi;
            if (p < 0x00010000UL)
                continue;
            if (VirtualQuery((LPCVOID)p, &mbi, sizeof(mbi)) != sizeof(mbi))
                continue;
            if (mbi.State != MEM_COMMIT)
                continue;
            if (!(mbi.Protect & (PAGE_READONLY | PAGE_READWRITE | PAGE_WRITECOPY |
                                 PAGE_EXECUTE_READ | PAGE_EXECUTE_READWRITE)))
                continue;
            /* clamp the 48-byte window to the committed region */
            {
                DWORD region_end = (DWORD)mbi.BaseAddress + (DWORD)mbi.RegionSize;
                DWORD avail = region_end - p;
                DWORD n = avail < 48 ? avail : 48;
                const DWORD *w = (const DWORD *)p;
                DWORD k;
                char line[160];
                int off = 0;
                off += wsprintfA(line + off, "  [%s=%08lX]", names[r], p);
                for (k = 0; k + 4 <= n && k < 48; k += 4)
                    off += wsprintfA(line + off, " %08lX", w[k / 4]);
                pmc_log("crash", "%s", line);
            }
        }
    }

    /* Entity post-mortem: find an Entity (first dword == 0xBDB410 vtable) in the
     * GP registers OR on the stack, and dump up to 3 distinct ones. The GlobalEnter
     * entity-component walk holds the owning entity `this` on the stack, so even
     * when the FAULTING object is a component (e.g. vtable 0xBAA0A0 / 0xA600D4 with
     * a NULL field), the entity that owns it is reachable here. Names the culprit
     * regardless of which leaf of the walk trips — no breakpoint / per-frame cost. */
    {
        DWORD seen[3];
        int n_seen = 0, k;
        const DWORD regs[6] = { cx->Eax, cx->Ecx, cx->Edx, cx->Ebx, cx->Esi, cx->Edi };
        int r, i;
        for (r = 0; r < 6 && n_seen < 3; r++) {
            DWORD p = regs[r];
            int dup = 0;
            if (safe_avail(p) < 4 || *(const DWORD *)p != ENTITY_VTABLE) continue;
            for (k = 0; k < n_seen; k++) if (seen[k] == p) dup = 1;
            if (!dup) { dump_entity(p); seen[n_seen++] = p; }
        }
        if (er->ExceptionCode != EXCEPTION_STACK_OVERFLOW) {
            const DWORD *sp = (const DWORD *)cx->Esp;
            for (i = 0; i < 192 && n_seen < 3; i++) {
                DWORD v = sp[i];
                int dup = 0;
                if (v < 0x00010000UL || safe_avail(v) < 4) continue;
                if (*(const DWORD *)v != ENTITY_VTABLE) continue;
                for (k = 0; k < n_seen; k++) if (seen[k] == v) dup = 1;
                if (dup) continue;
                pmc_log("crash", "  (entity on stack @esp+%03X)", i * 4);
                dump_entity(v);
                seen[n_seen++] = v;
            }
        }
        if (n_seen == 0)
            pmc_log("crash", "  (no Entity vtable 0xBDB410 found in regs/stack)");
    }

    /* Targeted: the 0x4AB26B model-segment spawn-walk (param/model/segment not
     * reachable via the generic Entity scan since the regs are all small ints). */
    if (eip >= SPAWN_WALK_LO && eip < SPAWN_WALK_HI &&
        er->ExceptionCode == EXCEPTION_ACCESS_VIOLATION)
        dump_spawn_walk(cx);

    /* PRMG render-resource registry miss (FUN_0047a6c0 / FUN_0047aa20 family:
     * 0x47A6FB record+0 deref, 0x47AA5C / 0x47A7D8 record+4 / entity loop). */
    if (eip >= 0x0047A600UL && eip < 0x0047AC00UL &&
        er->ExceptionCode == EXCEPTION_ACCESS_VIOLATION)
        dump_prmg_registry(cx);

    pmc_log_flush();
    InterlockedExchange(&g_inHandler, 0);
}

static LONG CALLBACK VehHandler(EXCEPTION_POINTERS *ep)
{
    if (is_severe(ep->ExceptionRecord->ExceptionCode))
        log_exception(ep, "VEH", 0);    /* first-chance: throttled per EIP */
    return EXCEPTION_CONTINUE_SEARCH;   /* don't alter behavior — just record */
}

static LONG WINAPI UnhandledFilter(EXCEPTION_POINTERS *ep)
{
    log_exception(ep, "UNHANDLED", 1);  /* fatal/last-chance: ALWAYS log */
    return EXCEPTION_EXECUTE_HANDLER;   /* terminate; we've recorded it */
}

void InstallCrashHandler(void)
{
    AddVectoredExceptionHandler(1, VehHandler);   /* 1 = first in the VEH chain */
    SetUnhandledExceptionFilter(UnhandledFilter);
    pmc_log("crash", "Crash handler armed (VEH + UnhandledExceptionFilter) — "
            "faults logged to source [crash].");
    pmc_log_flush();
}
