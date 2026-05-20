/**
 * cruise.dll — SecuROM Spoof + Debug Console + ASI Loader
 *              for Mercenaries 2: World in Flames
 *
 * Self-contained entry point that replaces the need for a separate ASI loader
 * (xinput1_3.dll / dinput8.dll proxy). Loaded via the game's import table.
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
 *
 * The DLL exports a single function by ordinal #1 (matching the original cruise.dll
 * import-by-ordinal interface used by the patched EXE).
 *
 * Build (MinGW cross-compile from macOS/Linux):
 *   i686-w64-mingw32-gcc -shared -o cruise.dll cruise.c cruise.def \
 *       -lkernel32 -luser32 -O2 -s -Wl,--enable-stdcall-fixup
 *
 * Architecture: 32-bit (x86) Windows DLL — Mercenaries 2 is a 32-bit game.
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <string.h>

#define CRUISE_VERSION "2.0.0"
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

/* --- Debug console --- */

static void InitDebugConsole(void) {
    AllocConsole();
    SetConsoleTitleA("Mercenaries 2 - Debug Console");

    freopen("CONOUT$", "w", stdout);
    freopen("CONOUT$", "w", stderr);

    printf("============================================\n");
    printf("  Mercenaries 2: World in Flames\n");
    printf("  cruise.dll v%s (ASI Loader)\n", CRUISE_VERSION);
    printf("============================================\n");
    printf("  PID: %lu\n", (unsigned long)GetCurrentProcessId());
    printf("  SecuROM event: created (signaled)\n");
    printf("============================================\n\n");
}

/* --- ASI plugin loader --- */

static HINSTANCE g_hinstSelf = NULL;

/**
 * Case-insensitive check whether a filename should be skipped (self-load prevention).
 * Skips: cruise.dll, cruise.asi, and the DLL's own module filename.
 */
static int IsSelfModule(const char *filename) {
    if (_stricmp(filename, "cruise.dll") == 0) return 1;
    if (_stricmp(filename, "cruise.asi") == 0) return 1;

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
            printf("  [LOADED] %s%s\n", display_prefix, fd.cFileName);
            (*out_loaded)++;
        } else {
            DWORD err = GetLastError();
            printf("  [FAILED] %s%s (error: 0x%08lX)\n",
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

    printf("[ASI Loader]\n");
    printf("  Base: %s\n\n", exe_dir);

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
        printf("  (no .asi plugins found)\n");
    }
    printf("\n  Summary: %d loaded, %d failed, %d total\n\n", loaded, failed, total);
}

/* --- Exported function (ordinal #1) ---
 *
 * The patched EXE imports cruise.dll by ordinal #1. This function is the
 * target of that import. It doesn't need to do anything — the real work
 * happens in DllMain. But the export must exist for the import to resolve.
 */
__declspec(dllexport) int __stdcall CruiseEntry(void) {
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

        /* Load all .asi plugins (replaces external ASI loader) */
        LoadASIPlugins();
    }
    return TRUE;
}
