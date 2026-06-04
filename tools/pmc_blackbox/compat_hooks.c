/**
 * compat_hooks.c — Runtime compatibility hook implementation
 *
 * Hooks the game's core lookup/resolution functions to provide:
 *   - Structured diagnostic logging on lookup failures
 *   - Safe fallback behavior (skip, clamp) to prevent NULL crashes
 *   - Session statistics for modders
 *
 * Hook targets (confirmed via x32dbg crash investigation):
 *   P1: 0x8242B0 — Generic hash table lookup (diagnostic-only)
 *   P2: 0x464780 — GetChunkDataReader (stub reader on NULL return)
 *   P3: 0x74D6D0 — Vertex declaration validator (clamp stream index)
 *
 * Superseded patches (removed — stub reader makes them unnecessary):
 *   P4: 0x45B1C9 — was inline code-cave NULL guard for chunk reader
 *   P5: 0x59CFF2 — was inline code-cave NULL guard for tag dispatch
 *   0x750B90     — static EXE patch in patch_anim_table.py (still present,
 *                  now redundant, remove in future cleanup)
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

static volatile LONG g_statHashMisses      = 0;
static volatile LONG g_statHashUnique      = 0;
static volatile LONG g_statNullReaders     = 0;
static volatile LONG g_statStreamClamps    = 0;

#define UNIQUE_HASH_CAPACITY 256
static volatile LONG  g_uniqueHashCount = 0;
static DWORD          g_uniqueHashes[UNIQUE_HASH_CAPACITY];

/*
 * Lock-free unique hash recording.  The previous implementation used a
 * CRITICAL_SECTION, which could deadlock when the hash hook fires on the
 * D3D9 rendering thread while the main thread holds the same lock (or
 * waits on the render queue that this thread must complete).
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
    pmc_log("compat", "  NULL chunk readers (stub returns): %ld",
            (long)g_statNullReaders);
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
 * A separate C helper handles the miss-logging path.
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

/* --- Stub Reader Object ---
 *
 * When GetChunkDataReader returns NULL (chunk not present in this WAD),
 * instead of propagating NULL to callers that dereference without checking,
 * the P2 hook returns a pointer to this static stub object.  It has a valid
 * vtable where all methods are safe no-ops, so callers can dereference
 * vtable slots, call Read(), and touch fields like [reader+0x10] without
 * crashing.
 *
 * This replaces per-caller code-cave patches (the old P4 at 0x45B1C9 and
 * P5 at 0x59CFF2) with a single fix at the source.
 *
 * Memory layout (single VirtualAlloc PAGE_EXECUTE_READWRITE block):
 *
 *   +0x00  Thunk code (machine code for no-op returns):
 *            +0x00  C3              ret        — default no-op (0-arg __thiscall)
 *            +0x01  C2 04 00        ret 4      — 1-arg cleanup
 *            +0x04  C2 08 00        ret 8      — 2-arg cleanup
 *            +0x07  31 C0 C2 0C 00     xor eax,eax; ret 12  — Read() returns 0 (S_OK)
 *
 *   +0x10  vtable[8] (DWORD pointers into thunk area):
 *            [0..4] → thunk_ret    (plain ret)
 *            [5]    → thunk_read   (Read: return 0/S_OK, clean 3 stack args)
 *            [6..7] → thunk_ret    (plain ret)
 *
 *   +0x30  Reader object (0x20 bytes):
 *            [+0x00] = &vtable
 *            [+0x04 .. +0x0C] = 0
 *            [+0x10] = 0          (position low — callers increment this)
 *            [+0x14] = 0          (position high)
 *            [+0x18] = &dummy_buf (buffer base — callers index directly!)
 *            [+0x1C] = 0          (buffer size / remaining)
 *
 *   +0x50  Dummy buffer (256 bytes, zeroed):
 *            Safe read target — callers that index into [+0x18] get zeros.
 *
 * Callers observed to access:
 *   [reader+0x00] — vtable pointer
 *   [reader+0x10] — position counter (INFO handler: add [reader+0x10], 1)
 *   [reader+0x18] — buffer pointer  (INFO handler: movzx ax,[buf+pos])
 *   vtable[5]     — Read() (__thiscall, ret 12, returns 0 = S_OK)
 *
 * NOTE: The static EXE patch at 0x750B90 in patch_anim_table.py (texture
 * BODY processor caller) is also made redundant by the stub reader but
 * lives in a separate file.  Remove it in a future cleanup pass.
 */

#define STUB_ALLOC_SIZE     0x150
#define STUB_THUNK_OFFSET   0x00
#define STUB_VTABLE_OFFSET  0x10
#define STUB_OBJECT_OFFSET  0x30
#define STUB_BUFFER_OFFSET  0x50
#define STUB_BUFFER_SIZE    0x100
#define STUB_VTABLE_SLOTS   8

static void *g_stubReader = NULL;

static int AllocStubReader(void) {
    BYTE *block;
    DWORD *vtable;
    DWORD *obj;
    DWORD base;
    int i;

    block = (BYTE *)VirtualAlloc(NULL, STUB_ALLOC_SIZE,
                                 MEM_COMMIT | MEM_RESERVE,
                                 PAGE_EXECUTE_READWRITE);
    if (!block) {
        pmc_log("compat", "AllocStubReader: VirtualAlloc failed");
        return 0;
    }
    memset(block, 0, STUB_ALLOC_SIZE);
    base = (DWORD)(DWORD_PTR)block;

    /* +0x00: ret */
    block[0x00] = 0xC3;
    /* +0x01: ret 4 */
    block[0x01] = 0xC2; block[0x02] = 0x04; block[0x03] = 0x00;
    /* +0x04: ret 8 */
    block[0x04] = 0xC2; block[0x05] = 0x08; block[0x06] = 0x00;
    /* +0x07: xor eax,eax; ret 12 — Read() returns 0 (S_OK) */
    block[0x07] = 0x31; block[0x08] = 0xC0;
    block[0x09] = 0xC2; block[0x0A] = 0x0C; block[0x0B] = 0x00;

    vtable = (DWORD *)(block + STUB_VTABLE_OFFSET);
    for (i = 0; i < STUB_VTABLE_SLOTS; i++)
        vtable[i] = base + 0x00;    /* default: plain ret */
    vtable[5] = base + 0x07;        /* Read(): xor eax,eax; ret 12 */

    obj = (DWORD *)(block + STUB_OBJECT_OFFSET);
    obj[0] = base + STUB_VTABLE_OFFSET;  /* +0x00: vtable ptr */
    obj[6] = base + STUB_BUFFER_OFFSET;  /* +0x18: buffer base → dummy buf */

    FlushInstructionCache(GetCurrentProcess(), block, STUB_ALLOC_SIZE);

    g_stubReader = (void *)obj;
    pmc_log("compat", "  StubReader @ 0x%08X (vtable 0x%08X, thunks 0x%08X)",
            (unsigned)(base + STUB_OBJECT_OFFSET),
            (unsigned)(base + STUB_VTABLE_OFFSET),
            (unsigned)(base + STUB_THUNK_OFFSET));
    return 1;
}

/* --- Hook: GetChunkDataReader (0x464780) ---
 *
 * Returns a reader object for chunk data, or NULL if the chunk is missing.
 * When NULL, the hook substitutes g_stubReader so callers never see NULL.
 * Actual calling convention (confirmed via trampoline + ret 0x04):
 *   __stdcall with 1 arg (chunkTablePtr).
 *   Prologue: test eax,eax / push ebp / mov ebp,[esp+8] / ...
 *   Epilogue: pop ebp / ret 0x04
 *   Note: EAX is also an input (tested before any stack reads).
 */

#define ADDR_GET_CHUNK_DATA_READER ((LPVOID)0x464780)

typedef void* (__stdcall *fn_GetChunkDataReader)(void *chunkTablePtr);
static fn_GetChunkDataReader g_origGetChunkDataReader = NULL;

/*
 * IMPORTANT: This hook must be fully non-blocking.  GetChunkDataReader is
 * called from ANY thread, including the D3D9 rendering thread.  The main
 * thread's render-queue drain loop (Sleep(0) at 0x8766E7) deadlocks if the
 * render thread blocks in pmc_log I/O.  Same pattern as P1 — atomic
 * counting only; totals printed at session shutdown via PrintCompatStats().
 */
static void* __stdcall Detour_GetChunkDataReader(void *chunkTablePtr) {
    void *result = g_origGetChunkDataReader(chunkTablePtr);

    if (result == NULL) {
        InterlockedIncrement(&g_statNullReaders);

        if ((int)g_hookMode >= PMC_HOOK_BREAK) {
            DebugBreak();
        }

        return g_stubReader;
    }

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
 * scratch in game memory).
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
        { ADDR_HASH_TABLE_LOOKUP,
          (LPVOID)Detour_HashTableLookup,
          (LPVOID*)&g_origHashTableLookup,
          "HashTableLookup" },

        { ADDR_GET_CHUNK_DATA_READER,
          (LPVOID)Detour_GetChunkDataReader,
          (LPVOID*)&g_origGetChunkDataReader,
          "GetChunkDataReader" },

        { ADDR_VERTEX_DECL_VALIDATOR,
          (LPVOID)Detour_VertexDeclValidator,
          (LPVOID*)&g_origVertexDeclValidator,
          "VertexDeclValidator" },
    };

    if (!AllocStubReader()) {
        pmc_log("compat", "FATAL: stub reader allocation failed, P2 hook unsafe");
        return 0;
    }

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
