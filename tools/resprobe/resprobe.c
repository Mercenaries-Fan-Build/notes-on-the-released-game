/**
 * resprobe.asi — resource instantiation probe (standalone diagnostic ASI; does NOT touch pmc_bb).
 *
 * Goal: name the v5 sub-resource that is REQUESTED but never reaches status 4 ("instantiated/resident"),
 * which is why the player object never goes "awake" after a mattias_v5 wardrobe swap.
 *
 * Addresses verified against the DEPLOYED Mercenaries2.exe (53,482,288 bytes; image base 0x400000,
 * no ASLR). output/_ghidra VAs == deployed VAs. (An earlier build used a DIFFERENT exe's addresses
 * (mercs2_v1.1_uncracked.exe, 53,944,080 bytes) and crashed on boot — patched garbage.)
 *
 *   REQ  = FUN_008731f0 Stream_Resource_LookupOrCreate : EAX = {nameHash@+0, typeHash@+4} key ptr.
 *          Prologue 53 55 8B 6C 24 0C (push ebx; push ebp; mov ebp,[esp+0xC]) — 6 clean bytes.
 *   DONE = FUN_00873140 Stream_Resource_Acquire (sets record+0x14 = 4) : [ESP+4] = key ptr.
 *          Prologue 53 8B 5C 24 08 (push ebx; mov ebx,[esp+8]) — 5 clean bytes.
 *   key shape: key[0]=nameHash, key[1]=typeHash. type hashes: model=0x5B724250, texture=0xF011157A,
 *              soundbank=0x9F8BCA10, effect=0x5608BD5A, wavebank=0xF753F6D0.
 *
 * A {nameHash} that appears in REQ but never in DONE (within the swap window) is the stall.
 *
 * Hot-path safety: detours do ZERO I/O — push {tag,hash,type} into a lock-free, deduped ring; a
 * watcher thread flushes to resprobe.log + pmc_log. Naked detours preserve all live-input registers.
 *
 * Loaded by pmc_bb.dll / Ultimate ASI Loader from <game>/scripts/. Refuses a mismatched exe.
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include "MinHook.h"

#define EXPECTED_EXE_SIZE   53482288
#define REQ_VA              0x008731F0   /* LookupOrCreate: EAX = key ptr {nameHash@0, typeHash@4} */
#define DONE_VA             0x00873140   /* Acquire (sets status 4): [ESP+4] = key ptr            */

#define EV_REQ 1
#define EV_DONE 2

/* Non-static so the naked detours' asm can reference the MinHook trampolines. */
void *g_origReq  = NULL;
void *g_origDone = NULL;

static BOOL   g_exeOk = FALSE;
static HANDLE g_log   = INVALID_HANDLE_VALUE;
typedef void (*pfn_pmc_log)(const char *source, const char *fmt, ...);
static pfn_pmc_log g_pmc_log = NULL;

/* ---- lock-free ring (hot path writes; watcher flushes) ---- */
typedef struct { DWORD tag, hash, type; } Ev;
#define RING_CAP 300000
static Ev            g_ring[RING_CAP];
static volatile LONG g_head = 0;
static LONG          g_tail = 0;
static volatile LONG g_dropped = 0;

/* ---- dedupe: log each {tag,hash} once ---- */
#define SEEN_CAP 262144
static volatile LONG g_seen[SEEN_CAP];
static int Seen(DWORD tag, DWORD hash) {
    DWORD key = (hash * 2u) + (tag == EV_DONE ? 1u : 0u);
    if (key == 0) key = 0xFFFFFFFFu;
    DWORD slot = (key * 2654435761u) & (SEEN_CAP - 1);
    DWORD p;
    for (p = 0; p < 64; p++) {
        DWORD idx = (slot + p) & (SEEN_CAP - 1);
        LONG cur = g_seen[idx];
        if ((DWORD)cur == key) return 1;
        if (cur == 0) {
            if (InterlockedCompareExchange(&g_seen[idx], (LONG)key, 0) == 0) return 0;
            if ((DWORD)g_seen[idx] == key) return 1;
        }
    }
    return 0;
}

/* Recorder: read the {nameHash,typeHash} key, dedupe, push one event. ZERO I/O. */
static void Record(DWORD tag, DWORD keyptr) {
    DWORD hash = 0, type = 0;
    if (keyptr >= 0x10000 && keyptr < 0x80000000) {
        hash = *(DWORD *)keyptr;
        type = *(DWORD *)(keyptr + 4);
    }
    if (Seen(tag, hash)) return;
    LONG i = InterlockedIncrement(&g_head) - 1;
    if (i >= 0 && i < RING_CAP) { g_ring[i].tag = tag; g_ring[i].hash = hash; g_ring[i].type = type; }
    else InterlockedIncrement(&g_dropped);
}
void __cdecl RecReq (DWORD keyptr) { Record(EV_REQ,  keyptr); }
void __cdecl RecDone(DWORD keyptr) { Record(EV_DONE, keyptr); }

/* REQ detour: 0x8731f0 takes the key ptr in EAX (live input). Save EAX, pass its value to RecReq,
 * preserve EAX/ECX/EDX, tail-jump to trampoline. */
__attribute__((naked, used))
void Detour_Req(void) {
    __asm__ (
        "pushl %eax\n\t"        /* [esp+8] after next 2 pushes = saved key ptr */
        "pushl %ecx\n\t"
        "pushl %edx\n\t"
        "pushl 8(%esp)\n\t"     /* arg = saved EAX (key ptr) */
        "call _RecReq\n\t"
        "addl $4, %esp\n\t"
        "popl %edx\n\t"
        "popl %ecx\n\t"
        "popl %eax\n\t"         /* restore EAX (key ptr) */
        "jmp *_g_origReq\n\t"
    );
}

/* DONE detour: 0x873140 takes the key ptr at [ESP+4]. After our 3 pushes that's [esp+0x10]. */
__attribute__((naked, used))
void Detour_Done(void) {
    __asm__ (
        "pushl %eax\n\t"
        "pushl %ecx\n\t"
        "pushl %edx\n\t"
        "movl 0x10(%esp), %eax\n\t"   /* eax = original [ESP+4] = key ptr */
        "pushl %eax\n\t"
        "call _RecDone\n\t"
        "addl $4, %esp\n\t"
        "popl %edx\n\t"
        "popl %ecx\n\t"
        "popl %eax\n\t"
        "jmp *_g_origDone\n\t"
    );
}

/* ------------------------------------------------------------------ logging (watcher thread only) */

static void LogInit(void) {
    char path[MAX_PATH], *slash; HMODULE bb;
    GetModuleFileNameA(NULL, path, MAX_PATH);
    slash = strrchr(path, '\\');
    if (slash) strcpy(slash + 1, "resprobe.log"); else strcpy(path, "resprobe.log");
    g_log = CreateFileA(path, GENERIC_WRITE, FILE_SHARE_READ, NULL,
                        CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    bb = GetModuleHandleA("pmc_bb.dll");
    if (bb) g_pmc_log = (pfn_pmc_log)GetProcAddress(bb, "pmc_log");
}

/* Self-timestamped, own-file ONLY. We do NOT call pmc_log per-event: the 10k+ REQ lines would
 * flood the blackbox and drown out the [dlc_skin] swap/awake markers we need to correlate against.
 * resprobe.log wall-clock timestamps match the blackbox's, so the two logs line up by time. */
static void Log(const char *fmt, ...) {
    char buf[600]; va_list ap; int len, hl; SYSTEMTIME st;
    GetLocalTime(&st);
    hl = wsprintfA(buf, "[%02d:%02d:%02d.%03d] ", st.wHour, st.wMinute, st.wSecond, st.wMilliseconds);
    va_start(ap, fmt); len = wvsprintfA(buf + hl, fmt, ap); va_end(ap);
    if (len <= 0) return;
    len += hl;
    if (g_log != INVALID_HANDLE_VALUE) {
        DWORD w; buf[len] = '\r'; buf[len + 1] = '\n';
        WriteFile(g_log, buf, len + 2, &w, NULL);
    }
}

static const char *TypeName(DWORD t) {
    switch (t) {
        case 0x5B724250: return "model";
        case 0xF011157A: return "texture";
        case 0x9F8BCA10: return "soundbank";
        case 0x5608BD5A: return "effect";
        case 0xF753F6D0: return "wavebank";
        default:         return "?";
    }
}

static BOOL VerifyExeSize(void) {
    char path[MAX_PATH]; HANDLE h; DWORD size;
    GetModuleFileNameA(NULL, path, MAX_PATH);
    h = CreateFileA(path, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
    if (h == INVALID_HANDLE_VALUE) return FALSE;
    size = GetFileSize(h, NULL); CloseHandle(h);
    return (size == EXPECTED_EXE_SIZE);
}

static DWORD WINAPI Watcher(LPVOID p) {
    (void)p;
    for (;;) {
        Sleep(400);
        LONG head = g_head;
        int flushed = 0;
        while (g_tail < head && g_tail < RING_CAP) {
            Ev *e = &g_ring[g_tail];
            Log("%s hash=%08X type=%08X (%s)",
                e->tag == EV_REQ ? "REQ" : e->tag == EV_DONE ? "DONE" : "???",
                e->hash, e->type, TypeName(e->type));
            g_tail++; flushed++;
        }
        if (flushed && g_log != INVALID_HANDLE_VALUE) FlushFileBuffers(g_log);
        if (g_dropped) { Log("WARN ring overflow, dropped=%ld", (long)g_dropped); g_dropped = 0; }
    }
}

/* ------------------------------------------------------------------ install */

static int InstallOne(DWORD va, void *detour, void **orig, const char *name) {
    if (MH_CreateHook((LPVOID)(DWORD_PTR)va, detour, orig) != MH_OK) { Log("MH_CreateHook(%s) failed", name); return 0; }
    if (MH_EnableHook((LPVOID)(DWORD_PTR)va) != MH_OK)               { Log("MH_EnableHook(%s) failed", name); return 0; }
    Log("hook armed: %s @0x%08lX", name, (unsigned long)va);
    return 1;
}

BOOL WINAPI DllMain(HINSTANCE h, DWORD reason, LPVOID r) {
    (void)r;
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(h);
        LogInit();
        g_exeOk = VerifyExeSize();
        Log("============================================");
        Log("resprobe.asi loaded (PID %lu, exe_ok=%d) — REQ/DONE resource-instantiation probe (deployed-exe addrs)",
            (unsigned long)GetCurrentProcessId(), g_exeOk);
        if (!g_exeOk) { Log("REFUSING: EXE size != %d", EXPECTED_EXE_SIZE); Log("====="); return TRUE; }
        if (MH_Initialize() != MH_OK) { Log("MH_Initialize failed"); return TRUE; }
        InstallOne(REQ_VA,  (void *)Detour_Req,  (void **)&g_origReq,  "FUN_008731F0(LookupOrCreate=REQ)");
        InstallOne(DONE_VA, (void *)Detour_Done, (void **)&g_origDone, "FUN_00873140(Acquire/status4=DONE)");
        CreateThread(NULL, 0, Watcher, NULL, 0, NULL);
        Log("REQ=requested, DONE=reached status 4. A hash REQ'd but never DONE = the stall.");
        Log("============================================");
    } else if (reason == DLL_PROCESS_DETACH) {
        if (g_log != INVALID_HANDLE_VALUE) { CloseHandle(g_log); g_log = INVALID_HANDLE_VALUE; }
    }
    return TRUE;
}
