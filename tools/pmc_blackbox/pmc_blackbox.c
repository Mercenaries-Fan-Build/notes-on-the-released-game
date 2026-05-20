/**
 * pmc_bb.dll — SecuROM Spoof + Debug Console + ASI Loader
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
 *   3. Discovers and LoadLibrary's all .asi plugins from:
 *      - Game root directory
 *      - scripts/ subfolder
 *      - plugins/ subfolder
 *      - update/ subfolder
 *   4. Reports load success/failure for each plugin
 *   5. Exports pmc_log() — centralized logging API for all ASI plugins.
 *      Writes timestamped, source-tagged lines to the console AND to a
 *      single pmc_blackbox.log file on disk.
 *
 * The DLL exports BlackboxEntry by ordinal #1 (the game's import table
 * resolves this by ordinal) and pmc_log by name.
 *
 * Build (MinGW cross-compile from macOS/Linux):
 *   i686-w64-mingw32-gcc -shared -o pmc_bb.dll pmc_blackbox.c pmc_blackbox.def \
 *       -lkernel32 -luser32 -O2 -s -Wl,--enable-stdcall-fixup
 *
 * Architecture: 32-bit (x86) Windows DLL — Mercenaries 2 is a 32-bit game.
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

#define PMC_BLACKBOX_VERSION "2.1.0"
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

static void InitLogFile(void) {
    char exe_dir[MAX_PATH];
    GetModuleFileNameA(NULL, exe_dir, MAX_PATH);
    char *sep = strrchr(exe_dir, '\\');
    if (sep) *(sep + 1) = '\0';

    char log_path[MAX_PATH];
    wsprintfA(log_path, "%spmc_blackbox.log", exe_dir);
    g_logfile = fopen(log_path, "w");

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

    EnterCriticalSection(&g_logLock);

    fputs(line, stdout);
    fflush(stdout);

    if (g_logfile) {
        fputs(line, g_logfile);
        fflush(g_logfile);
    }

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

static void FixSpawnValidation(void) {
    BYTE* flag = (BYTE*)0x00DFBD74;
    DWORD oldProtect;
    if (VirtualProtect(flag, 1, PAGE_READWRITE, &oldProtect)) {
        *flag = 0x01;
        VirtualProtect(flag, 1, oldProtect, &oldProtect);
        pmc_log("blackbox", "Spawn validation flag set (0x00DFBD74 = 0x01)");
    }
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

        /* Fix underground spawn — must run before first spawn call */
        FixSpawnValidation();

        /* Load all .asi plugins (replaces external ASI loader) */
        LoadASIPlugins();
    }
    return TRUE;
}
