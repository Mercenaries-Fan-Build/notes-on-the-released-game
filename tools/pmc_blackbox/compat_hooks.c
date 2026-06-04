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
#include "minhook/MinHook.h"

/* pmc_log is defined in pmc_blackbox.c; same compilation unit (DLL) */
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
 * Signature: int __cdecl HashTableLookup(uint32_t hashKey, int tableSize)
 * Returns slot index (>=0) on hit, -1 on miss.
 */

#define ADDR_HASH_TABLE_LOOKUP ((LPVOID)0x8242B0)

typedef int (__cdecl *fn_HashTableLookup)(DWORD hashKey, int tableSize);
static fn_HashTableLookup g_origHashTableLookup = NULL;

static int __cdecl Detour_HashTableLookup(DWORD hashKey, int tableSize) {
    int result = g_origHashTableLookup(hashKey, tableSize);

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
 * Signature: void* __cdecl GetChunkDataReader(...)
 * We pass through all args via the trampoline; we only inspect the return.
 */

#define ADDR_GET_CHUNK_DATA_READER ((LPVOID)0x464780)

typedef void* (__cdecl *fn_GetChunkDataReader)(void);
static fn_GetChunkDataReader g_origGetChunkDataReader = NULL;

static void* __cdecl Detour_GetChunkDataReader(void) {
    void *result = g_origGetChunkDataReader();

    if (result == NULL) {
        int mode = (int)g_hookMode;
        InterlockedIncrement(&g_statNullReaders);

        if (mode >= PMC_HOOK_LOG) {
            void *caller = __builtin_return_address(0);
            pmc_log("compat", "NULL_READER chunk_caller=0x%08X",
                    (unsigned int)(DWORD_PTR)caller);
        }
        if (mode >= PMC_HOOK_BREAK) {
            DebugBreak();
        }
    }

    return result;
}

/* --- Hook: Vertex Declaration Validator (0x74D6D0) ---
 *
 * Uses a stream index to index a stack-local array[16]. Stream indices > 15
 * overflow the array (crash at 0x74D839). We clamp to valid range.
 * Signature: int __cdecl VertexDeclValidator(uint32_t streamIdx, ...)
 */

#define ADDR_VERTEX_DECL_VALIDATOR ((LPVOID)0x74D6D0)
#define MAX_STREAM_INDEX 15

typedef int (__cdecl *fn_VertexDeclValidator)(unsigned int streamIdx, void *arg2, void *arg3);
static fn_VertexDeclValidator g_origVertexDeclValidator = NULL;

static int __cdecl Detour_VertexDeclValidator(unsigned int streamIdx, void *arg2, void *arg3) {
    if (streamIdx > MAX_STREAM_INDEX) {
        int mode = (int)g_hookMode;
        InterlockedIncrement(&g_statStreamClamps);

        if (mode >= PMC_HOOK_LOG) {
            pmc_log("compat", "CLAMP stream_idx=%u->%u caller=0x74D839",
                    streamIdx, MAX_STREAM_INDEX);
        }
        if (mode >= PMC_HOOK_BREAK) {
            DebugBreak();
        }
        streamIdx = MAX_STREAM_INDEX;
    }

    return g_origVertexDeclValidator(streamIdx, arg2, arg3);
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

    InitializeCriticalSection(&g_uniqueHashLock);

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
    DeleteCriticalSection(&g_uniqueHashLock);
}
