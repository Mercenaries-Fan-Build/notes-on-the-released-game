/**
 * pmc_bb.dll — SecuROM Spoof + Debug Console + ASI Loader + Compat Hooks
 *                    for Mercenaries 2: World in Flames
 *
 * Self-contained entry point that replaces the need for a separate ASI loader
 * (xinput1_3.dll / dinput8.dll proxy). Loaded via the game's import table.
 *
 * IMPORTANT: The game's import table must reference "pmc_bb.dll" (not
 * "cruise.dll"). The exe patcher (tools/apply_securom_patch.py) handles this
 * automatically — it injects pmc_bb.dll into the import table.
 *
 * Responsibilities:
 *   1. Creates the SecuROM v7 spoof Event (mandatory for game boot)
 *   2. Allocates a debug console window with stdout/stderr redirection
 *   3. Installs runtime compatibility hooks (MinHook) for crash prevention
 *   4. Fixes underground spawn validation
 *   5. Discovers and LoadLibrary's all .asi plugins from:
 *      - Game root directory
 *      - scripts/ subfolder
 *      - plugins/ subfolder
 *      - update/ subfolder
 *   6. Reports load success/failure for each plugin
 *   7. Exports pmc_log() — centralized logging API for all ASI plugins.
 *      Writes timestamped, source-tagged lines to the console AND to a
 *      single pmc_blackbox.log file on disk.
 *
 * The DLL exports BlackboxEntry by ordinal #1 (the game's import table
 * resolves this by ordinal) and pmc_log by name.
 *
 * Build (MinGW cross-compile):
 *   make mingw   (see Makefile for full command)
 *
 * Architecture: 32-bit (x86) Windows DLL — Mercenaries 2 is a 32-bit game.
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include "lua_log_hook.h"

#define PMC_BLACKBOX_VERSION "3.0.0"
#define SECUROM_XOR_KEY 0x19EA3FD3

/* --- SecuROM event spoof --- */

static HANDLE g_securomEvent = NULL;

static void CreateSecuROMEvent(void) {
    DWORD pid = GetCurrentProcessId();
    DWORD derived = pid ^ SECUROM_XOR_KEY;
    char event_name[32];
    wsprintfA(event_name, "v7_%04d", derived);
    g_securomEvent = CreateEventA(NULL, TRUE, TRUE, event_name);
}

/* --- Centralized logging --- */

static FILE*           g_logfile = NULL;
static CRITICAL_SECTION g_logLock;

static volatile LONG g_logPending = 0;
volatile LONG g_logDropped = 0;
/* Flush every line: a buffered tail is lost on a hard crash, and the missing
 * lines previously made an end-of-load fault (STATE_WAITFORSTREAMING) look like
 * an early-init one. fflush per line is cheap for a debug logger and keeps the
 * crash-time tail truthful. Raise this only if log volume becomes a hot path. */
#define LOG_FLUSH_THRESHOLD 1

static void InitLogFile(void) {
    char exe_dir[MAX_PATH];
    GetModuleFileNameA(NULL, exe_dir, MAX_PATH);
    char *sep = strrchr(exe_dir, '\\');
    if (sep) *(sep + 1) = '\0';

    char log_path[MAX_PATH];
    wsprintfA(log_path, "%spmc_blackbox.log", exe_dir);
    g_logfile = fopen(log_path, "w");
    if (g_logfile)
        setvbuf(g_logfile, NULL, _IOFBF, 8192);

    InitializeCriticalSection(&g_logLock);
}

/**
 * Shared logging function exported for all ASI plugins.
 *
 * Formats a timestamped, source-tagged message and writes it to both the
 * debug console (stdout) and the pmc_blackbox.log file on disk.
 *
 * ASI plugins resolve this at runtime via GetProcAddress("pmc_log").
 */
__declspec(dllexport) void pmc_log(const char *source, const char *fmt, ...) {
    char msg[1024];
    va_list ap;
    va_start(ap, fmt);
    wvsprintfA(msg, fmt, ap);
    va_end(ap);

    SYSTEMTIME st;
    GetLocalTime(&st);
    char line[1200];
    wsprintfA(line, "[%02d:%02d:%02d.%03d] [%s] %s\n",
              st.wHour, st.wMinute, st.wSecond, st.wMilliseconds,
              source ? source : "???", msg);

    /*
     * Use TryEnterCriticalSection so callers on latency-sensitive threads
     * (D3D9 rendering, audio) never block.  Dropped messages are counted
     * via g_logDropped and reported at shutdown.
     */
    if (!TryEnterCriticalSection(&g_logLock)) {
        InterlockedIncrement(&g_logDropped);
        return;
    }

    fputs(line, stdout);

    if (g_logfile)
        fputs(line, g_logfile);

    if (InterlockedIncrement(&g_logPending) >= LOG_FLUSH_THRESHOLD) {
        fflush(stdout);
        if (g_logfile) fflush(g_logfile);
        InterlockedExchange(&g_logPending, 0);
    }

    LeaveCriticalSection(&g_logLock);
}

__declspec(dllexport) void pmc_log_flush(void) {
    EnterCriticalSection(&g_logLock);
    fflush(stdout);
    if (g_logfile) fflush(g_logfile);
    InterlockedExchange(&g_logPending, 0);
    LeaveCriticalSection(&g_logLock);
}

/* --- Debug console --- */

static void InitDebugConsole(void) {
    AllocConsole();
    SetConsoleTitleA("Mercenaries 2 - PMC Blackbox");

    freopen("CONOUT$", "w", stdout);
    freopen("CONOUT$", "w", stderr);

    InitLogFile();

    pmc_log("blackbox", "============================================");
    pmc_log("blackbox", "  Mercenaries 2: World in Flames");
    pmc_log("blackbox", "  PMC Blackbox v%s (ASI Loader)", PMC_BLACKBOX_VERSION);
    pmc_log("blackbox", "============================================");
    pmc_log("blackbox", "  PID: %lu", (unsigned long)GetCurrentProcessId());
    pmc_log("blackbox", "  SecuROM event: created (signaled)");
    pmc_log("blackbox", "============================================");
}

/* --- Underground spawn fix --- */

#define SPAWN_FLAG_VA  0x00DFBD74
#define SPAWN_FIX_REAPPLY_DELAY_MS  5000
#define SPAWN_FIX_REAPPLY_COUNT     4
#define SPAWN_FIX_REAPPLY_INTERVAL  3000

static void WriteSpawnFlag(void) {
    BYTE* flag = (BYTE*)SPAWN_FLAG_VA;
    DWORD oldProtect;
    if (VirtualProtect(flag, 1, PAGE_READWRITE, &oldProtect)) {
        *flag = 0x01;
        VirtualProtect(flag, 1, oldProtect, &oldProtect);
    }
}

static void FixSpawnValidation(void) {
    WriteSpawnFlag();
    pmc_log("blackbox", "Spawn validation flag set (0x%08X = 0x01)", SPAWN_FLAG_VA);
}

/*
 * The game's initialization (MOVQ store at ~0x006CEEBA) zeroes the .data region
 * containing the spawn flag AFTER DllMain has already set it.  Re-apply the flag
 * on a background thread after a delay so it persists past that zeroing.
 */
static DWORD WINAPI SpawnFlagWatchdog(LPVOID param) {
    (void)param;
    Sleep(SPAWN_FIX_REAPPLY_DELAY_MS);
    for (int i = 0; i < SPAWN_FIX_REAPPLY_COUNT; i++) {
        BYTE current = *(volatile BYTE*)SPAWN_FLAG_VA;
        if (current != 0x01) {
            WriteSpawnFlag();
            pmc_log("blackbox", "Spawn flag re-applied (was 0x%02X, pass %d/%d)",
                    current, i + 1, SPAWN_FIX_REAPPLY_COUNT);
        }
        if (i < SPAWN_FIX_REAPPLY_COUNT - 1)
            Sleep(SPAWN_FIX_REAPPLY_INTERVAL);
    }
    return 0;
}

/* --- ASI plugin loader --- */

static HINSTANCE g_hinstSelf = NULL;

/**
 * Case-insensitive check whether a filename should be skipped (self-load prevention).
 * Skips: pmc_bb.dll, pmc_bb.asi, and the DLL's own module filename.
 */
static int IsSelfModule(const char *filename) {
    if (_stricmp(filename, "pmc_bb.dll") == 0) return 1;
    if (_stricmp(filename, "pmc_bb.asi") == 0) return 1;

    char self_name[MAX_PATH];
    if (GetModuleFileNameA(g_hinstSelf, self_name, MAX_PATH)) {
        char *sep = strrchr(self_name, '\\');
        const char *self_base = sep ? sep + 1 : self_name;
        if (_stricmp(filename, self_base) == 0) return 1;
    }
    return 0;
}

/**
 * Load all .asi files from a single directory.
 * Returns the number of plugins attempted (loaded + failed).
 */
static int LoadASIsFromDirectory(const char *dir_path, const char *display_prefix,
                                 int *out_loaded, int *out_failed) {
    char search_path[MAX_PATH];
    char full_path[MAX_PATH];
    WIN32_FIND_DATAA fd;
    HANDLE hFind;
    int count = 0;

    wsprintfA(search_path, "%s*.asi", dir_path);
    hFind = FindFirstFileA(search_path, &fd);
    if (hFind == INVALID_HANDLE_VALUE) return 0;

    do {
        if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) continue;
        if (IsSelfModule(fd.cFileName)) continue;

        wsprintfA(full_path, "%s%s", dir_path, fd.cFileName);

        HMODULE hMod = LoadLibraryA(full_path);
        if (hMod) {
            pmc_log("blackbox", "  [LOADED] %s%s", display_prefix, fd.cFileName);
            (*out_loaded)++;
        } else {
            DWORD err = GetLastError();
            pmc_log("blackbox", "  [FAILED] %s%s (error: 0x%08lX)",
                       display_prefix, fd.cFileName, (unsigned long)err);
            (*out_failed)++;
        }
        count++;
    } while (FindNextFileA(hFind, &fd));
    FindClose(hFind);

    return count;
}

/**
 * Discover and load .asi plugins from the standard search paths:
 *   1. Game root (exe directory)
 *   2. scripts/
 *   3. plugins/
 *   4. update/
 *
 * This matches the Ultimate ASI Loader's search paths, so existing
 * configurations (scripts/global.ini, file layout) work unchanged.
 * xinput1_3.dll (or any other ASI loader proxy) can be removed entirely.
 */
static void LoadASIPlugins(void) {
    char exe_dir[MAX_PATH];
    char sub_dir[MAX_PATH];
    int total = 0, loaded = 0, failed = 0;

    GetModuleFileNameA(NULL, exe_dir, MAX_PATH);
    char *last_sep = strrchr(exe_dir, '\\');
    if (last_sep) *(last_sep + 1) = '\0';

    pmc_log("blackbox", "[ASI Loader]");
    pmc_log("blackbox", "  Base: %s", exe_dir);

    /* 1. Game root */
    total += LoadASIsFromDirectory(exe_dir, "", &loaded, &failed);

    /* 2. scripts/ */
    wsprintfA(sub_dir, "%sscripts\\", exe_dir);
    total += LoadASIsFromDirectory(sub_dir, "scripts\\", &loaded, &failed);

    /* 3. plugins/ */
    wsprintfA(sub_dir, "%splugins\\", exe_dir);
    total += LoadASIsFromDirectory(sub_dir, "plugins\\", &loaded, &failed);

    /* 4. update/ */
    wsprintfA(sub_dir, "%supdate\\", exe_dir);
    total += LoadASIsFromDirectory(sub_dir, "update\\", &loaded, &failed);

    if (total == 0) {
        pmc_log("blackbox", "  (no .asi plugins found)");
    }
    pmc_log("blackbox", "  Summary: %d loaded, %d failed, %d total", loaded, failed, total);
}

/* --- Runtime compat patches (the proven exe-patch, applied IN MEMORY) ---
 *
 * Mirrors tools/patch_anim_table.py exactly (auto-generated into
 * compat_patches.gen.c by tools/pmc_blackbox/gen_compat_patches.py). The headline
 * fix is the anim/stance hash-table expansion 1024 -> 4096 in FUN_0067cfb0: the DLC
 * resident ActionTable has 1036 entries, overflowing the fixed 1024-slot table and
 * livelocking the world load at the 0x67D130 linear probe (we measured exactly 13
 * stuck streaming nodes = 1036 - 1023). Expanding to 4096 (count 0x400->0x1000,
 * mask 0x3FF->0xFFF, stack frame + table-base offsets shifted) gives ample headroom.
 * Also includes the hash-zero sentinel fix and the texture/effect/vtxdecl NULL
 * guards from the same proven patch set.
 *
 * Applied here at DllMain time — the EXE image is fully mapped before an imported
 * DLL's DllMain runs (same as the spawn-flag write below) — so 0x67CFB0 etc. are
 * live. Each patch verifies the expected original bytes first; if the bytes already
 * match the patched form (e.g. running a pre-patched exe) it is counted as
 * already-present, and any true mismatch is skipped+logged (never corrupts an
 * unexpected build). NOT an exe edit: Mercenaries2.exe on disk is untouched. */
typedef struct {
    DWORD va;
    const unsigned char *exp;
    const unsigned char *pat;
    unsigned int len;
    const char *desc;
} CompatPatch;
extern const CompatPatch g_compatPatches[];
extern const unsigned int g_compatPatchCount;

static void ApplyCompatPatches(void) {
    unsigned int applied = 0, already = 0, mismatch = 0, failed = 0;
    HANDLE proc = GetCurrentProcess();
    unsigned int i;

    pmc_log("compat", "[Runtime exe-patch] anim-table 1024->4096 + DLC compat guards (%u patches)",
            g_compatPatchCount);

    for (i = 0; i < g_compatPatchCount; i++) {
        const CompatPatch *cp = &g_compatPatches[i];
        BYTE *addr = (BYTE *)cp->va;
        DWORD oldProt;

        if (!VirtualProtect(addr, cp->len, PAGE_EXECUTE_READWRITE, &oldProt)) {
            failed++;
            pmc_log("compat", "  [FAIL vprotect] 0x%08lX  %s", (unsigned long)cp->va, cp->desc);
            continue;
        }
        if (memcmp(addr, cp->exp, cp->len) == 0) {
            memcpy(addr, cp->pat, cp->len);
            applied++;
        } else if (memcmp(addr, cp->pat, cp->len) == 0) {
            already++;
        } else {
            mismatch++;
            pmc_log("compat", "  [SKIP mismatch] 0x%08lX  %s", (unsigned long)cp->va, cp->desc);
        }
        VirtualProtect(addr, cp->len, oldProt, &oldProt);
        FlushInstructionCache(proc, addr, cp->len);
    }

    pmc_log("compat", "Compat patches: %u applied, %u already-present, %u mismatch, %u vprotect-fail (of %u)",
            applied, already, mismatch, failed, g_compatPatchCount);
    if (mismatch > 0) {
        pmc_log("compat", "  WARNING: %u patch site(s) had unexpected bytes — wrong exe build? "
                          "Those sites were left untouched.", mismatch);
    }
}

/* --- Exported function (ordinal #1) ---
 *
 * The patched EXE imports pmc_bb.dll by ordinal #1. This function is
 * the target of that import. It doesn't need to do anything — the real work
 * happens in DllMain. But the export must exist for the import to resolve.
 */
__declspec(dllexport) int __stdcall BlackboxEntry(void) {
    return 1;
}

/* --- DLL entry point --- */

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
    (void)lpvReserved;

    if (fdwReason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(hinstDLL);
        g_hinstSelf = hinstDLL;

        /* The SecuROM event MUST be created before the Sitext stub checks it */
        CreateSecuROMEvent();

        /* Debug console — safe in DllMain for AllocConsole */
        InitDebugConsole();

        /* NOTE: the former compat_hooks.c engine detours (hash-lookup 0x8242B0,
         * GetChunkDataReader 0x464780, vertex-decl clamp 0x74D6D0) have been REMOVED.
         * They were live MinHook detours that ran our code on hot, multi-threaded
         * engine paths; one faulted early init at 0x45B1D2, another was a passive
         * counter, and the vertex-decl one merely CLAMPED stream indices — masking
         * bad DLC data rather than fixing it. The real fixes are the in-memory
         * compat patches below (and correct converter output). */

        /* Runtime exe-patch: anim-table 1024->4096 expansion + DLC compat guards,
         * applied in memory (no exe edit). The DLC ActionTable (1036 entries)
         * overflows the stock 1024-slot table -> world-load livelock; this is the
         * fix. Built from the proven tools/patch_anim_table.py patch set.
         * Opt out with -DPMC_NO_RUNTIME_PATCH for a control run. */
#ifdef PMC_NO_RUNTIME_PATCH
        pmc_log("compat", "runtime exe-patch DISABLED at build time (control run)");
#else
        ApplyCompatPatches();
#endif

        /* Native Lua message capture — patch the game's print/Debug.Printf
         * func-pointer slots so every Lua-level log line (incl. the "global
         * start" world-load marker) is recorded to pmc_blackbox.log.
         *
         * ON by default — pmc_bb is the self-contained capture, replacing the
         * dlc_enable god-object. Opt out only for a control run with
         * -DPMC_DISABLE_LUA_LOG_HOOK. See [[pmc-bb-native-lua-logging]]. */
#ifndef PMC_DISABLE_LUA_LOG_HOOK
        InstallLuaLogHook();
#else
        pmc_log("blackbox", "Lua log hook: DISABLED at build time (control run)");
#endif

        /* Fix underground spawn — early write + deferred watchdog thread.
         * Game init zeroes this flag; the watchdog re-applies it. */
        FixSpawnValidation();
        CreateThread(NULL, 0, SpawnFlagWatchdog, NULL, 0, NULL);

        /* Load all .asi plugins (replaces external ASI loader) */
        LoadASIPlugins();
    }
    return TRUE;
}
