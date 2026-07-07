/**
 * cf340_proxy.asi — dynamic limit-adjuster / proxy-heap for FUN_004cf340's record buffers
 *
 * Loaded by pmc_bb.dll / Ultimate ASI Loader from <game>/scripts/.
 *
 * THE BUG (named by poolguard): FUN_004cf340 (the CHDR/NODE/STAT/INFO compiled-expression reader
 * at 0x004CF340) assembles texture-reference records into pool buffers sized for base-game
 * density. The denser DLC node writes past a buffer end, splattering 0xF011157A across the heap →
 * corrupts adjacent free-list links (grid/pool-pop crashes) AND component vtables (FUN_007E0420
 * wild calls). One overflow, all crash variants.
 *
 * THE FIX (your fastman92 / Open-Limit-Adjuster proxy-heap idea, runtime/dynamic): hook the fast
 * pool allocator FUN_0084DCE0 and, for allocations whose CLIENT caller is inside FUN_004cf340,
 * request a LARGER block (orig + headroom) from the pool's own bigger classes. The block stays a
 * real pool block so the engine's normal free path reclaims it; the overrun just gets room.
 *
 * CRITICAL CALLING-CONVENTION NOTE: FUN_0084DCE0 reads BOTH ECX (size class) AND EAX (the real
 * size — set by the game at 0x4CF6B8 `mov eax,[ebp-4]` right before `call DCE0`). A plain C
 * __fastcall detour clobbers EAX before calling the original and corrupts the allocator (this
 * caused an early AV at 0x02476051). So we use a NAKED detour that preserves EAX/EDX and only
 * rewrites ECX, and we do ZERO I/O on the hot path (stats go through a background watcher thread).
 *
 * Modes (env CF340_MODE): "fix" (default) bumps; "measure" counts only. Env CF340_HEADROOM = extra
 * bytes (default 0x400). Watcher logs running stats to cf340_proxy.log every ~1.5 s.
 * 
 * NOTE: THIS DOES NOT FIX THE ISSUE - it's present state causes the game to hang just after the main menu.
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "MinHook.h"

#define EXPECTED_EXE_SIZE   53482288
#define TEXT_START_VA       0x00401000
#define TEXT_SIZE           0x00703000
#define DCE0_VA             0x0084DCE0      /* fast pool: reads ECX=class AND EAX=size -> EAX=ptr */
#define D760_VA             0x0084D760      /* slow alloc: __stdcall(poolDesc,size,rounded) + AL=1 */

/* FUN_004cf340 body range (entry .. just past its alloc sites). poolguard logged its alloc-site
 * return addresses as 0x4CF4E7 / 0x4CF5AD / 0x4CF6A6 — all inside this window. */
#define CF340_LO            0x004CF340
#define CF340_HI            0x004CF710

static int IsAllocFrame(DWORD v) {
    return (v >= 0x0084A000 && v < 0x0084E300)
        || (v >= 0x0088C800 && v < 0x0088CD00);
}

/* Non-static so the naked detours' asm can reference them: the MinHook trampolines. */
void *g_origDCE0 = NULL;
void *g_origD760 = NULL;

static BOOL  g_exeOk    = FALSE;
static int   g_fixMode  = 1;              /* default FIX; CF340_MODE=measure opts out */
static DWORD g_headroom = 0x10;          /* small: universal small-buffer headroom (16B) */
static DWORD g_maxBumpSize = 0x80;       /* only bump allocs <= this many bytes (record buffers) */
static HANDLE g_log     = INVALID_HANDLE_VALUE;
static volatile LONG g_nDCE0 = 0, g_nD760 = 0, g_nCf340 = 0, g_nBumped = 0, g_maxCf340 = 0;

typedef void (*pfn_pmc_log)(const char *source, const char *fmt, ...);
static pfn_pmc_log g_pmc_log = NULL;

/* ------------------------------------------------------------------ logging (NOT on hot path) */

static void LogInit(void) {
    char path[MAX_PATH], *slash; HMODULE bb;
    GetModuleFileNameA(NULL, path, MAX_PATH);
    slash = strrchr(path, '\\');
    if (slash) strcpy(slash + 1, "cf340_proxy.log"); else strcpy(path, "cf340_proxy.log");
    g_log = CreateFileA(path, GENERIC_WRITE, FILE_SHARE_READ, NULL,
                        CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_WRITE_THROUGH, NULL);
    bb = GetModuleHandleA("pmc_bb.dll");
    if (bb) g_pmc_log = (pfn_pmc_log)GetProcAddress(bb, "pmc_log");
}

static void Log(const char *fmt, ...) {
    char buf[512]; va_list ap; int len;
    va_start(ap, fmt); len = wvsprintfA(buf, fmt, ap); va_end(ap);
    if (len <= 0) return;
    if (g_log != INVALID_HANDLE_VALUE) {
        DWORD w; buf[len] = '\r'; buf[len + 1] = '\n';
        WriteFile(g_log, buf, len + 2, &w, NULL); FlushFileBuffers(g_log); buf[len] = '\0';
    }
    if (g_pmc_log) g_pmc_log("cf340", "%s", buf);
}

static BOOL VerifyExeSize(void) {
    char path[MAX_PATH]; HANDLE h; DWORD size;
    GetModuleFileNameA(NULL, path, MAX_PATH);
    h = CreateFileA(path, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
    if (h == INVALID_HANDLE_VALUE) return FALSE;
    size = GetFileSize(h, NULL); CloseHandle(h);
    return (size == EXPECTED_EXE_SIZE);
}

/* Walk the stack for the first .text return address that is NOT an allocator frame — the real
 * client caller (FUN_004cf340 for the buffers we want). `anchor` points at the saved return
 * address in the naked detour's frame. Passive (read only) — safe on the hot path. */
static DWORD ScanClientCaller(void *anchor) {
    DWORD *sp = (DWORD *)anchor; int i;
    for (i = 0; i < 64; i++) {
        DWORD v = sp[i];
        if (v >= TEXT_START_VA && v < (TEXT_START_VA + TEXT_SIZE) && !IsAllocFrame(v)) return v;
    }
    return 0;
}

/* Bump targets: loader call-sites whose small record buffers overrun adjacent free-list links
 * (each named by poolguard's overflower scan). Extensible — add a range per confirmed overflower.
 * Kept under the name IsCf340 so the two hot-path callers don't need editing. */
static int IsCf340(DWORD c) {
    if (c >= CF340_LO && c < CF340_HI) return 1;          /* FUN_004cf340 texture-record reader   */
    if (c >= 0x00414A00 && c < 0x00414C80) return 1;       /* FUN_00414xxx Havok-packfile loader    */
    return 0;                                              /*   (poolguard: P->next=0x10C0C013 =    */
}                                                          /*    Havok magic 0x10C0C010 + 3)        */
static unsigned RoundUp16(unsigned v) { return (v + 15u) & ~15u; }

/* Hot-path helper called from the naked detour with __cdecl. Returns the ECX size to use.
 * ZERO I/O here — only lock-free counters; the watcher thread reports them. */
unsigned __cdecl DecideBumpDCE0(unsigned ecxSize, void *anchor) {
    DWORD caller = ScanClientCaller(anchor);
    InterlockedIncrement(&g_nDCE0);
    if (!IsCf340(caller)) return ecxSize;
    InterlockedIncrement(&g_nCf340);
    { LONG o = (LONG)ecxSize, cur;
      do { cur = g_maxCf340; if (o <= cur) break; }
      while (InterlockedCompareExchange(&g_maxCf340, o, cur) != cur); }
    if (!g_fixMode) return ecxSize;
    InterlockedIncrement(&g_nBumped);
    return RoundUp16(ecxSize + g_headroom);
}

/* Naked detour: preserves EAX (DCE0's implicit size input) and EDX, rewrites only ECX, then
 * tail-jumps to the trampoline with the stack exactly as DCE0 expects ([esp]=retAddr). */
__attribute__((naked, used))
void Detour_DCE0(void) {
    __asm__ (
        "pushl %eax\n\t"               /* save EAX (DCE0 reads it as the real size)   */
        "pushl %edx\n\t"               /* save EDX                                     */
        "leal 8(%esp), %edx\n\t"       /* EDX = &retAddr (scan anchor: [esp+8] now)    */
        "pushl %edx\n\t"               /* arg2: anchor                                 */
        "pushl %ecx\n\t"               /* arg1: ecxSize                                */
        "call _DecideBumpDCE0\n\t"     /* EAX = size to use in ECX                      */
        "addl $8, %esp\n\t"
        "movl %eax, %ecx\n\t"          /* ECX = decided size                           */
        "popl %edx\n\t"                /* restore EDX                                  */
        "popl %eax\n\t"                /* restore EAX (game's real size)               */
        "jmp *_g_origDCE0\n\t"         /* run original DCE0 with EAX/EDX intact         */
    );
}

/* D760 hot-path helper: modifies the __stdcall args IN PLACE on the caller's stack. `frame`
 * points at [retAddr, poolDesc, size, rounded]. Bumps size AND rounded for FUN_004cf340 callers,
 * so whichever the allocator uses gets headroom. ZERO I/O. */
void __cdecl AdjustD760(DWORD *frame) {
    DWORD caller = ScanClientCaller(frame);
    InterlockedIncrement(&g_nD760);
    if (!IsCf340(caller)) return;
    InterlockedIncrement(&g_nCf340);
    { LONG o = (LONG)frame[2], cur;
      do { cur = g_maxCf340; if (o <= cur) break; }
      while (InterlockedCompareExchange(&g_maxCf340, o, cur) != cur); }
    if (!g_fixMode) return;
    { unsigned bumped = RoundUp16((unsigned)frame[2] + g_headroom);
      InterlockedIncrement(&g_nBumped);
      frame[2] = bumped;                                   /* size   */
      if ((unsigned)frame[3] < bumped) frame[3] = (DWORD)bumped; }  /* rounded */
}

/* Naked detour for D760: preserves EAX (the AL=1 flag the game sets before the call) and ECX/EDX,
 * lets AdjustD760 bump the stack args in place, then tail-jumps to the trampoline. */
__attribute__((naked, used))
void Detour_D760(void) {
    __asm__ (
        "pushl %eax\n\t"               /* save EAX (AL input)                          */
        "pushl %edx\n\t"
        "pushl %ecx\n\t"
        "leal 12(%esp), %eax\n\t"      /* EAX = &retAddr  -> frame[0..3]               */
        "pushl %eax\n\t"               /* arg: frame                                   */
        "call _AdjustD760\n\t"         /* bumps frame[2]/[3] in place                   */
        "addl $4, %esp\n\t"
        "popl %ecx\n\t"
        "popl %edx\n\t"
        "popl %eax\n\t"                /* restore EAX                                  */
        "jmp *_g_origD760\n\t"         /* run original D760 with bumped args, AL intact */
    );
}

/* ------------------------------------------------------------------ watcher (off hot path) */

static DWORD WINAPI Watcher(LPVOID p) {
    (void)p;
    for (;;) {
        Sleep(1500);
        Log("stats: dce0=%ld d760=%ld cf340=%ld bumped=%ld maxCf340Size=%ld",
            (long)g_nDCE0, (long)g_nD760, (long)g_nCf340, (long)g_nBumped, (long)g_maxCf340);
    }
}

/* ------------------------------------------------------------------ install */

static int InstallOne(DWORD va, void *detour, void **orig, const char *name) {
    if (MH_CreateHook((LPVOID)(DWORD_PTR)va, detour, orig) != MH_OK) {
        Log("MH_CreateHook(%s) failed", name); return 0;
    }
    if (MH_EnableHook((LPVOID)(DWORD_PTR)va) != MH_OK) {
        Log("MH_EnableHook(%s) failed", name); return 0;
    }
    Log("hook armed: %s @0x%08lX", name, (unsigned long)va);
    return 1;
}

static void ReadConfig(void) {
    char v[32]; DWORD n;
    n = GetEnvironmentVariableA("CF340_MODE", v, sizeof(v));
    if (n && (lstrcmpiA(v, "measure") == 0)) g_fixMode = 0;
    else if (n && (lstrcmpiA(v, "fix") == 0)) g_fixMode = 1;
    n = GetEnvironmentVariableA("CF340_HEADROOM", v, sizeof(v));
    if (n) { DWORD h = (DWORD)strtoul(v, NULL, 0); if (h) g_headroom = h; }
}

BOOL WINAPI DllMain(HINSTANCE h, DWORD reason, LPVOID r) {
    (void)r;
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(h);
        LogInit();
        ReadConfig();
        g_exeOk = VerifyExeSize();
        Log("============================================");
        Log("cf340_proxy.asi loaded (PID %lu, exe_ok=%d, mode=%s, headroom=0x%X) [naked/EAX-safe]",
            (unsigned long)GetCurrentProcessId(), g_exeOk,
            g_fixMode ? "FIX" : "measure", (unsigned)g_headroom);
        if (!g_exeOk) { Log("REFUSING: EXE size != %d", EXPECTED_EXE_SIZE); Log("====="); return TRUE; }
        if (MH_Initialize() != MH_OK) { Log("MH_Initialize failed"); return TRUE; }
        InstallOne(DCE0_VA, (void *)Detour_DCE0, (void **)&g_origDCE0, "FUN_0084DCE0");
        InstallOne(D760_VA, (void *)Detour_D760, (void **)&g_origD760, "FUN_0084D760");
        Log("watching client callers in [0x%06X,0x%06X) on DCE0 + D760", CF340_LO, CF340_HI);
        CreateThread(NULL, 0, Watcher, NULL, 0, NULL);
        Log("============================================");
    } else if (reason == DLL_PROCESS_DETACH) {
        if (g_log != INVALID_HANDLE_VALUE) { CloseHandle(g_log); g_log = INVALID_HANDLE_VALUE; }
    }
    return TRUE;
}
