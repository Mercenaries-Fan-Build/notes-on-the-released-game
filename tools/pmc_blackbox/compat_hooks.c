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
 *   P2: 0x464780 — GetChunkDataReader (diagnostic-only)
 *   P3: 0x74D6D0 — Vertex declaration validator (clamp stream index)
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include "compat_hooks.h"

/* pmc_log is defined in pmc_blackbox.c; same compilation unit (DLL) */
extern void pmc_log(const char *source, const char *fmt, ...);

/* --- Dynamic MinHook loading ---
 * We load MinHook.x86.dll at runtime instead of vendoring the source.
 * This uses the official pre-built binary, avoiding subtle compilation issues.
 */

typedef enum MH_STATUS {
    MH_UNKNOWN = -1,
    MH_OK = 0,
    MH_ERROR_ALREADY_INITIALIZED,
    MH_ERROR_NOT_INITIALIZED,
    MH_ERROR_ALREADY_CREATED,
    MH_ERROR_NOT_CREATED,
    MH_ERROR_ENABLED,
    MH_ERROR_DISABLED,
    MH_ERROR_NOT_EXECUTABLE,
    MH_ERROR_UNSUPPORTED_FUNCTION,
    MH_ERROR_MEMORY_ALLOC,
    MH_ERROR_MEMORY_PROTECT,
    MH_ERROR_MODULE_NOT_FOUND,
    MH_ERROR_FUNCTION_NOT_FOUND
} MH_STATUS;

#define MH_ALL_HOOKS NULL

typedef MH_STATUS (WINAPI *pfn_MH_Initialize)(void);
typedef MH_STATUS (WINAPI *pfn_MH_Uninitialize)(void);
typedef MH_STATUS (WINAPI *pfn_MH_CreateHook)(LPVOID, LPVOID, LPVOID*);
typedef MH_STATUS (WINAPI *pfn_MH_EnableHook)(LPVOID);
typedef MH_STATUS (WINAPI *pfn_MH_DisableHook)(LPVOID);
typedef const char* (WINAPI *pfn_MH_StatusToString)(MH_STATUS);

static pfn_MH_Initialize      p_MH_Initialize      = NULL;
static pfn_MH_Uninitialize     p_MH_Uninitialize     = NULL;
static pfn_MH_CreateHook       p_MH_CreateHook       = NULL;
static pfn_MH_EnableHook       p_MH_EnableHook       = NULL;
static pfn_MH_DisableHook      p_MH_DisableHook      = NULL;
static pfn_MH_StatusToString   p_MH_StatusToString   = NULL;
static HMODULE                 g_hMinHook            = NULL;

static int LoadMinHook(void) {
    g_hMinHook = LoadLibraryA("MinHook.x86.dll");
    if (!g_hMinHook) {
        pmc_log("compat", "FATAL: MinHook.x86.dll not found (place next to exe)");
        return 0;
    }
    p_MH_Initialize    = (pfn_MH_Initialize)   GetProcAddress(g_hMinHook, "MH_Initialize");
    p_MH_Uninitialize  = (pfn_MH_Uninitialize) GetProcAddress(g_hMinHook, "MH_Uninitialize");
    p_MH_CreateHook    = (pfn_MH_CreateHook)   GetProcAddress(g_hMinHook, "MH_CreateHook");
    p_MH_EnableHook    = (pfn_MH_EnableHook)   GetProcAddress(g_hMinHook, "MH_EnableHook");
    p_MH_DisableHook   = (pfn_MH_DisableHook)  GetProcAddress(g_hMinHook, "MH_DisableHook");
    p_MH_StatusToString = (pfn_MH_StatusToString)GetProcAddress(g_hMinHook, "MH_StatusToString");

    if (!p_MH_Initialize || !p_MH_CreateHook || !p_MH_EnableHook) {
        pmc_log("compat", "FATAL: MinHook.x86.dll missing required exports");
        FreeLibrary(g_hMinHook);
        g_hMinHook = NULL;
        return 0;
    }
    pmc_log("compat", "MinHook.x86.dll loaded OK");
    return 1;
}

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
static CRITICAL_SECTION g_uniqueHashLock;

static void RecordUniqueHash(DWORD hash) {
    LONG i, count;

    EnterCriticalSection(&g_uniqueHashLock);
    count = g_uniqueHashCount;
    for (i = 0; i < count; i++) {
        if (g_uniqueHashes[i] == hash) {
            LeaveCriticalSection(&g_uniqueHashLock);
            return;
        }
    }
    if (count < UNIQUE_HASH_CAPACITY) {
        g_uniqueHashes[count] = hash;
        g_uniqueHashCount = count + 1;
        InterlockedIncrement(&g_statHashUnique);
    }
    LeaveCriticalSection(&g_uniqueHashLock);
}

void PrintCompatStats(void) {
    pmc_log("compat", "=== Session Summary ===");
    pmc_log("compat", "  Hash lookup misses: %ld (%ld unique hashes)",
            (long)g_statHashMisses, (long)g_statHashUnique);
    pmc_log("compat", "  NULL chunk readers: %ld", (long)g_statNullReaders);
    pmc_log("compat", "  Stream index clamps: %ld", (long)g_statStreamClamps);
}

/* --- Hook: Hash Table Lookup (0x8242B0) ---
 *
 * Generic hash table slot lookup used by effects, textures, meshes, etc.
 * Actual calling convention (confirmed via trampoline disasm):
 *   ECX = hashKey, first stack arg = tableSize
 *   Prologue: test ecx,ecx / push ebx / mov ebx,[esp+8] / ...
 * This is a __thiscall-like convention; the detour must use __fastcall
 * to capture ECX (hashKey) and EDX (unused) as register args, with
 * tableSize as the first stack arg after the two hidden register slots.
 * Returns slot index (>=0) on hit, -1 on miss.
 */

#define ADDR_HASH_TABLE_LOOKUP ((LPVOID)0x8242B0)

typedef int (__fastcall *fn_HashTableLookup)(DWORD hashKey, DWORD _edx_unused, int tableSize);
static fn_HashTableLookup g_origHashTableLookup = NULL;

static int __fastcall Detour_HashTableLookup(DWORD hashKey, DWORD _edx_unused, int tableSize) {
    int result = g_origHashTableLookup(hashKey, _edx_unused, tableSize);

    if (result == -1) {
        int mode = (int)g_hookMode;
        InterlockedIncrement(&g_statHashMisses);
        RecordUniqueHash(hashKey);

        if (mode >= PMC_HOOK_LOG) {
            void *caller = __builtin_return_address(0);
            pmc_log("compat", "MISS hash=0x%08X table_size=%d caller=0x%08X",
                    hashKey, tableSize, (unsigned int)(DWORD_PTR)caller);
        }
        if (mode >= PMC_HOOK_BREAK) {
            DebugBreak();
        }
    }

    return result;
}

/* --- Hook: GetChunkDataReader (0x464780) ---
 *
 * Returns a reader object for chunk data, or NULL if the chunk is missing.
 * Many callers dereference without NULL check.
 * Actual calling convention (confirmed via trampoline + ret 0x04):
 *   __stdcall with 1 arg (chunkTablePtr).
 *   Prologue: test eax,eax / push ebp / mov ebp,[esp+8] / ...
 *   Epilogue: pop ebp / ret 0x04
 *   Note: EAX is also an input (tested before any stack reads).
 */

#define ADDR_GET_CHUNK_DATA_READER ((LPVOID)0x464780)

typedef void* (__stdcall *fn_GetChunkDataReader)(void *chunkTablePtr);
static fn_GetChunkDataReader g_origGetChunkDataReader = NULL;

static void* __stdcall Detour_GetChunkDataReader(void *chunkTablePtr) {
    void *result = g_origGetChunkDataReader(chunkTablePtr);

    if (result == NULL) {
        int mode = (int)g_hookMode;
        InterlockedIncrement(&g_statNullReaders);

        if (mode >= PMC_HOOK_LOG) {
            void *caller = __builtin_return_address(0);
            pmc_log("compat", "NULL_READER chunk_caller=0x%08X ptr=0x%08X",
                    (unsigned int)(DWORD_PTR)caller,
                    (unsigned int)(DWORD_PTR)chunkTablePtr);
        }
        if (mode >= PMC_HOOK_BREAK) {
            DebugBreak();
        }
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
    const char *status_str;

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

    InitializeCriticalSection(&g_uniqueHashLock);

    if (!LoadMinHook()) return 0;

    status = p_MH_Initialize();
    if (status != MH_OK) {
        status_str = p_MH_StatusToString ? p_MH_StatusToString(status) : "?";
        pmc_log("compat", "MH_Initialize failed: %s", status_str);
        return 0;
    }

    for (i = 0; i < (int)(sizeof(hooks) / sizeof(hooks[0])); i++) {
        status = p_MH_CreateHook(hooks[i].target, hooks[i].detour, hooks[i].ppOriginal);
        if (status != MH_OK) {
            status_str = p_MH_StatusToString ? p_MH_StatusToString(status) : "?";
            pmc_log("compat", "  [SKIP] %s @ 0x%08X: %s",
                    hooks[i].name, (unsigned int)(DWORD_PTR)hooks[i].target,
                    status_str);
            continue;
        }
        installed++;
    }

    status = p_MH_EnableHook(MH_ALL_HOOKS);
    if (status != MH_OK) {
        status_str = p_MH_StatusToString ? p_MH_StatusToString(status) : "?";
        pmc_log("compat", "MH_EnableHook(ALL) failed: %s", status_str);
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
    if (p_MH_DisableHook)  p_MH_DisableHook(MH_ALL_HOOKS);
    if (p_MH_Uninitialize) p_MH_Uninitialize();
    DeleteCriticalSection(&g_uniqueHashLock);
    if (g_hMinHook) { FreeLibrary(g_hMinHook); g_hMinHook = NULL; }
}
