/**
 * compat_hooks.c — Runtime compatibility hook implementation
 *
 * Minimal, diagnostic-only hook layer.  These hooks observe what the engine
 * is doing on its core lookup/resolution paths and record statistics; they
 * do NOT lie to the engine (no stub objects, no synchronization patches, no
 * NULL substitution).  The engine sees real return values and behaves exactly
 * as it would without us.  The only mutation is a mild, safe input
 * sanitization in P3 (clamping an out-of-range stream index).
 *
 * Hook targets (confirmed via x32dbg crash investigation):
 *   P1: 0x8242B0 — Generic hash table lookup (passive: count misses)
 *   P2: 0x464780 — GetChunkDataReader (passive: count NULL returns)
 *   P3: 0x74D6D0 — Vertex declaration validator (clamp stream index in place)
 *
 * Note on the 0x750B90 static EXE patch in patch_anim_table.py: it remains in
 * place and addresses a genuine animation-table capacity/format issue.  An
 * earlier header revision flagged it as "redundant" relative to the (now
 * removed) stub reader; that note is retained for the record, but the static
 * patch is independent of this file and is intentionally left untouched.
 *
 * MinHook is compiled directly from submodules/minhook/ (git submodule).
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <string.h>
#include "compat_hooks.h"
#include "MinHook.h"

extern void pmc_log(const char *source, const char *fmt, ...);

/* --- Configuration --- */

static volatile LONG g_hookMode = PMC_HOOK_LOG;

void SetCompatHookMode(int mode) {
    InterlockedExchange(&g_hookMode, mode);
}

int GetCompatHookMode(void) {
    return (int)g_hookMode;
}

/* --- Statistics (atomic increments, lock-free reads) --- */

static volatile LONG g_statHashMisses   = 0;
static volatile LONG g_statHashUnique   = 0;
static volatile LONG g_statNullReaders  = 0;
static volatile LONG g_statStreamClamps = 0;

#define UNIQUE_HASH_CAPACITY 256
static volatile LONG  g_uniqueHashCount = 0;
static DWORD          g_uniqueHashes[UNIQUE_HASH_CAPACITY];

/*
 * Lock-free unique hash recording.  A CRITICAL_SECTION here could deadlock
 * when the hash hook fires on the D3D9 rendering thread while the main thread
 * holds the same lock (or waits on the render queue that this thread must
 * complete).
 *
 * Uses InterlockedCompareExchange to CAS-append.  Duplicates are benign
 * (the count is an approximation for diagnostics).
 */
static void RecordUniqueHash(DWORD hash) {
    LONG i, count;

    count = g_uniqueHashCount;
    for (i = 0; i < count; i++) {
        if (g_uniqueHashes[i] == hash)
            return;
    }
    if (count < UNIQUE_HASH_CAPACITY) {
        if (InterlockedCompareExchange(&g_uniqueHashCount, count + 1, count) == count) {
            g_uniqueHashes[count] = hash;
            InterlockedIncrement(&g_statHashUnique);
        }
    }
}

extern volatile LONG g_logDropped;

void PrintCompatStats(void) {
    pmc_log("compat", "=== Session Summary ===");
    pmc_log("compat", "  Hash lookup misses: %ld (%ld unique hashes)",
            (long)g_statHashMisses, (long)g_statHashUnique);
    pmc_log("compat", "  NULL chunk readers: %ld", (long)g_statNullReaders);
    pmc_log("compat", "  Stream index clamps: %ld", (long)g_statStreamClamps);
    if (g_logDropped > 0)
        pmc_log("compat", "  Log messages dropped (contention): %ld",
                (long)g_logDropped);
}

/* --- Hook: Hash Table Lookup (0x8242B0) ---
 *
 * Actual calling convention (confirmed via x32dbg disassembly of all
 * exit paths at 0x8242DC and 0x824398):
 *
 *   INPUT:  ECX = hashKey
 *           [ESP+4] = tableSize  (stack arg, after return address)
 *           ESI = hash table pointer  (implicit register input)
 *   OUTPUT: EAX = slot index (>=0) on hit, -1 on miss
 *   EXIT:   pop edi / pop ebp / pop ebx / ret   (plain ret, NO cleanup)
 *
 * This is a CUSTOM convention: ECX as a register arg with __cdecl-style
 * caller cleanup.  Using __fastcall is WRONG — it generates 'ret 4'
 * (callee pops the stack arg), but the original uses plain 'ret'.
 * The 4-byte stack over-cleanup causes progressive corruption: after
 * enough calls, the return address shifts into .data and the game
 * crashes executing zeroed memory.
 *
 * Fix: naked detour that matches the original convention exactly.
 * A separate C helper handles the miss-counting path.
 */

#define ADDR_HASH_TABLE_LOOKUP ((LPVOID)0x8242B0)

/*
 * Trampoline pointer — written by MH_CreateHook().
 * Non-static so the naked detour's basic asm can reference the symbol.
 */
void *g_origHashTableLookup = NULL;

/*
 * Miss-path helper — called from the naked detour with __cdecl.
 * Non-static so the naked detour's basic asm can reference the symbol.
 *
 * IMPORTANT: This function must be fully non-blocking.  It is called from
 * ANY thread that hits the hash table lookup, including the D3D9 rendering
 * thread (e.g. caller 0x00873217).  The main thread waits on a render-queue
 * drain loop (Sleep(0) at 0x8766E7) that blocks until the rendering thread
 * finishes its frame.  If this function calls pmc_log (which does fputs →
 * ZwWriteFile), the console/file I/O can block, stalling the render thread
 * and deadlocking the main thread's drain loop.
 *
 * Fix: atomic counting only.  Totals are printed at session shutdown via
 * PrintCompatStats().  For interactive diagnosis, use PMC_HOOK_BREAK mode
 * (triggers DebugBreak on the first miss) or read the stats in the debugger.
 */
void HashTableLookup_logMiss(DWORD hashKey, int tableSize, DWORD callerAddr) {
    (void)tableSize;
    (void)callerAddr;
    InterlockedIncrement(&g_statHashMisses);
    RecordUniqueHash(hashKey);
}

/*
 * Naked detour — matches the original function's register/stack protocol
 * exactly so that every caller (including high-address callers in .data
 * thunks or SecuROM stubs) gets correct stack cleanup.
 *
 * Strategy:
 *   1. Save EBX, stash hashKey there (trampoline preserves EBX for us)
 *   2. Call trampoline with original convention, do caller cleanup
 *   3. On miss, push __cdecl args and call the C helper
 *   4. Restore EBX, plain ret
 */
__attribute__((naked, used))
void Detour_HashTableLookup(void) {
    __asm__ (
        /* entry: ECX=hashKey, ESI=table, [ESP]=retAddr, [ESP+4]=tableSize */
        "pushl %ebx\n\t"
        "movl %ecx, %ebx\n\t"

        /* call trampoline: ECX=hashKey, push tableSize, caller cleanup */
        "pushl 8(%esp)\n\t"
        "call *_g_origHashTableLookup\n\t"
        "addl $4, %esp\n\t"

        /* EAX=result; trampoline restored EBX to our saved hashKey */
        "cmpl $-1, %eax\n\t"
        "jne 1f\n\t"

        /* miss: HashTableLookup_logMiss(hashKey, tableSize, callerAddr) */
        "movl 4(%esp), %eax\n\t"
        "pushl %eax\n\t"
        "pushl 12(%esp)\n\t"
        "pushl %ebx\n\t"
        "call _HashTableLookup_logMiss\n\t"
        "addl $12, %esp\n\t"
        "movl $-1, %eax\n\t"

        "1:\n\t"
        "popl %ebx\n\t"
        "ret\n\t"
    );
}

/* --- Hook: GetChunkDataReader (0x464780) ---
 *
 * Returns a reader object for chunk data, or NULL if the chunk is missing.
 * This hook is PASSIVE: it returns the original result unchanged, including
 * NULL, so the engine behaves exactly as it would without us.  On a NULL
 * return it only bumps an atomic counter.
 *
 * Actual calling convention (confirmed via trampoline + ret 0x04):
 *   __stdcall with 1 arg (chunkTablePtr).
 *   Prologue: test eax,eax / push ebp / mov ebp,[esp+8] / ...
 *   Epilogue: pop ebp / ret 0x04
 *   Note: EAX is also an input (tested before any stack reads).
 *
 * IMPORTANT: This hook must be fully non-blocking.  GetChunkDataReader is
 * called from ANY thread, including the D3D9 rendering thread.  The main
 * thread's render-queue drain loop (Sleep(0) at 0x8766E7) deadlocks if the
 * render thread blocks in pmc_log I/O.  Same pattern as P1 — atomic
 * counting only; totals printed at session shutdown via PrintCompatStats().
 */

#define ADDR_GET_CHUNK_DATA_READER ((LPVOID)0x464780)

typedef void* (__stdcall *fn_GetChunkDataReader)(void *chunkTablePtr);
static fn_GetChunkDataReader g_origGetChunkDataReader = NULL;

static void* __stdcall Detour_GetChunkDataReader(void *chunkTablePtr) {
    void *result = g_origGetChunkDataReader(chunkTablePtr);

    if (result == NULL)
        InterlockedIncrement(&g_statNullReaders);

    return result;
}

/* --- Hook: Vertex Declaration Validator (0x74D6D0) ---
 *
 * Validates a D3DVERTEXELEMENT9 array.  The function iterates the array
 * (8-byte elements, 0xFF end marker in the first u16) and uses each
 * element's Stream field (u16 at offset 0) to index a stack-local
 * array[16].  Stream values > 15 overflow that array (crash at 0x74D839:
 *   add [esp+ecx*4+0x20], edx   where ecx = Stream).
 *
 * Actual calling convention (confirmed via trampoline disasm):
 *   int __cdecl VertexDeclValidator(D3DVERTEXELEMENT9 *pDecl,
 *                                   int *pOutCount, void *arg3)
 *   Prologue: push ebp / mov ebp,esp / and esp,-8 / sub esp,0x54
 *   arg1 (pDecl) is a POINTER, NOT a stream index.
 *
 * Fix: walk the element array BEFORE calling the original function and
 * clamp any Stream field > 15 to 15 in-place (the array is writable
 * scratch in game memory).  This is mild, safe input sanitization, not a
 * substitution of engine behavior.
 */

#define ADDR_VERTEX_DECL_VALIDATOR ((LPVOID)0x74D6D0)
#define MAX_STREAM_INDEX 15
#define MAX_VERTEX_ELEMENTS 64

#pragma pack(push, 1)
typedef struct {
    WORD  Stream;
    WORD  Offset;
    BYTE  Type;
    BYTE  Method;
    BYTE  Usage;
    BYTE  UsageIndex;
} VertexElement9;
#pragma pack(pop)

typedef int (__cdecl *fn_VertexDeclValidator)(VertexElement9 *pDecl, int *pOutCount, void *arg3);
static fn_VertexDeclValidator g_origVertexDeclValidator = NULL;

static int __cdecl Detour_VertexDeclValidator(VertexElement9 *pDecl, int *pOutCount, void *arg3) {
    if (pDecl != NULL) {
        int i;
        for (i = 0; i < MAX_VERTEX_ELEMENTS; i++) {
            if (pDecl[i].Stream == 0xFF)
                break;
            if (pDecl[i].Stream > MAX_STREAM_INDEX) {
                int mode = (int)g_hookMode;
                InterlockedIncrement(&g_statStreamClamps);

                if (mode >= PMC_HOOK_LOG) {
                    pmc_log("compat", "CLAMP elem[%d].Stream=%u->%u",
                            i, (unsigned)pDecl[i].Stream, MAX_STREAM_INDEX);
                }
                if (mode >= PMC_HOOK_BREAK) {
                    DebugBreak();
                }
                pDecl[i].Stream = MAX_STREAM_INDEX;
            }
        }
    }

    return g_origVertexDeclValidator(pDecl, pOutCount, arg3);
}

/* --- Hook Installation --- */

typedef struct {
    LPVOID      target;
    LPVOID      detour;
    LPVOID     *ppOriginal;
    const char *name;
} HookDef;

int InstallCompatHooks(void) {
    MH_STATUS status;
    int installed = 0;
    int i;

    HookDef hooks[] = {
        /* The HashTableLookup detour (0x8242B0) is OFF by default: it faults the
         * EARLY-INIT path at 0x45b1d2 — a registry lookup (0x0084D760) routes
         * through the hooked hash table during startup, before any world load,
         * and the detour breaks it (reproduced again on a cross-machine build).
         * The other two detours boot clean. Opt in with -DPMC_ENABLE_HASH_HOOK
         * only for hash-miss diagnostics. (All compat off: -DPMC_NO_COMPAT_HOOKS.) */
#ifdef PMC_ENABLE_HASH_HOOK
        { ADDR_HASH_TABLE_LOOKUP,
          (LPVOID)Detour_HashTableLookup,
          (LPVOID*)&g_origHashTableLookup,
          "HashTableLookup" },
#endif

        { ADDR_GET_CHUNK_DATA_READER,
          (LPVOID)Detour_GetChunkDataReader,
          (LPVOID*)&g_origGetChunkDataReader,
          "GetChunkDataReader" },

        { ADDR_VERTEX_DECL_VALIDATOR,
          (LPVOID)Detour_VertexDeclValidator,
          (LPVOID*)&g_origVertexDeclValidator,
          "VertexDeclValidator" },
    };

    status = MH_Initialize();
    if (status != MH_OK) {
        pmc_log("compat", "MH_Initialize failed: %s", MH_StatusToString(status));
        return 0;
    }

    for (i = 0; i < (int)(sizeof(hooks) / sizeof(hooks[0])); i++) {
        status = MH_CreateHook(hooks[i].target, hooks[i].detour, hooks[i].ppOriginal);
        if (status != MH_OK) {
            pmc_log("compat", "  [SKIP] %s @ 0x%08X: %s",
                    hooks[i].name, (unsigned int)(DWORD_PTR)hooks[i].target,
                    MH_StatusToString(status));
            continue;
        }
        installed++;
    }

    status = MH_EnableHook(MH_ALL_HOOKS);
    if (status != MH_OK) {
        pmc_log("compat", "MH_EnableHook(ALL) failed: %s", MH_StatusToString(status));
        return 0;
    }

    pmc_log("compat", "Installed %d/%d hooks (mode=%s)",
            installed, (int)(sizeof(hooks) / sizeof(hooks[0])),
            g_hookMode == PMC_HOOK_SILENT ? "silent" :
            g_hookMode == PMC_HOOK_LOG    ? "log"    : "break");

    return installed;
}

void ShutdownCompatHooks(void) {
    PrintCompatStats();
    MH_DisableHook(MH_ALL_HOOKS);
    MH_Uninitialize();
}
