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
    switch (pool) { case POOL_DCE0: return "FUN_0084DCE0"; case POOL_POOL2: return "FUN_0088CB70"; }
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
 * The install-pop catch + dump.
 * ------------------------------------------------------------------ */

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
            Log(">>> OVERFLOWER allocation 0x%08lX not in alloc map (allocated pre-hook or via "
                "an un-hooked path) — identify it from below[0] header in Ghidra", (unsigned long)below);
    }
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

static void * __fastcall Detour_DCE0(unsigned int sizeHint) {
    int anchor = 0;
    void *r = g_origDCE0(sizeHint);
    DWORD p = (DWORD)(DWORD_PTR)r;
    if (p && g_recordEnabled) {
        DWORD caller = ScanClientCaller(&anchor);
        AHashPut(p, caller, sizeHint);
        CheckInstallPop(p, caller, POOL_DCE0);
        CheckDispenseLow(POOL_DCE0, p, sizeHint, caller);
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
    if (p && p >= POOL_MIN_VALID && g_recordEnabled)
        AHashPut(p, ScanClientCaller(&anchor), (DWORD)size);
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
        Log("poolguard.asi loaded (PID %lu, exe_verified=%d, record=%d, catchall=%d) [v11]",
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
