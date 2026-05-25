/**
 * net_hooks.asi — Network/Multiplayer Bypass for Mercenaries 2: World in Flames
 *
 * Hooks IsOnlineConnected, HasPlayerUnlockedCode, and IsMatchmakingInternet
 * to return TRUE, bypassing online connectivity checks. Uses dynamic scanning
 * of .rdata to find the Lua function pointers, then installs inline JMP hooks.
 *
 * IMPORTANT: Works with the cracked retail EXE (53,482,288 bytes).
 * All section VAs are binary-specific.
 *
 * Build: make mingw  (cross-compile with MinGW)
 * Install: Copy net_hooks.asi to <game>/scripts/
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

/* --- Section layout (cracked retail EXE) --- */

#define RDATA_START_VA      0x00B05000
#define RDATA_SIZE          0x000F1000
#define TEXT_START_VA       0x00401000
#define TEXT_SIZE           0x00703000

/* --- Lua types --- */

#define LUA_TBOOLEAN    1

typedef void* lua_State;
typedef int (*lua_CFunction)(lua_State* L);

/* --- Global state --- */

static HMODULE g_hModule = NULL;
static lua_CFunction g_origIsOnlineConnected = NULL;
static lua_CFunction g_origHasPlayerUnlockedCode = NULL;

/* --- Logging --- */

static HANDLE g_logFile = INVALID_HANDLE_VALUE;

static void LogInit(void) {
    char path[MAX_PATH];
    char *dot;

    GetModuleFileNameA(g_hModule, path, MAX_PATH);
    dot = strrchr(path, '.');
    if (dot) strcpy(dot, ".log");
    else strcat(path, ".log");

    g_logFile = CreateFileA(path, GENERIC_WRITE, FILE_SHARE_READ,
                            NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
}

static void Log(const char *fmt, ...) {
    char buf[1024];
    int len;
    va_list ap;
    DWORD written;

    va_start(ap, fmt);
    len = wvsprintfA(buf, fmt, ap);
    va_end(ap);

    if (len <= 0) return;

    if (g_logFile != INVALID_HANDLE_VALUE) {
        buf[len] = '\r';
        buf[len + 1] = '\n';
        WriteFile(g_logFile, buf, len + 2, &written, NULL);
        FlushFileBuffers(g_logFile);
    }
}

static void LogClose(void) {
    if (g_logFile != INVALID_HANDLE_VALUE) {
        CloseHandle(g_logFile);
        g_logFile = INVALID_HANDLE_VALUE;
    }
}

/* --- Memory scanning --- */

static DWORD FindStringInRdata(const char* target) {
    BYTE* base = (BYTE*)RDATA_START_VA;
    size_t len = strlen(target);
    for (DWORD i = 0; i < RDATA_SIZE - len; i++) {
        if (memcmp(base + i, target, len + 1) == 0) {
            return RDATA_START_VA + i;
        }
    }
    return 0;
}

static lua_CFunction FindLuaFuncForString(DWORD string_va) {
    BYTE* base = (BYTE*)RDATA_START_VA;
    for (DWORD i = 0; i < RDATA_SIZE - 8; i += 4) {
        DWORD val = *(DWORD*)(base + i);
        if (val == string_va) {
            DWORD func_va = *(DWORD*)(base + i + 4);
            if (func_va >= TEXT_START_VA &&
                func_va < TEXT_START_VA + TEXT_SIZE) {
                return (lua_CFunction)func_va;
            }
        }
    }
    return NULL;
}

/* --- Inline hook installation --- */

typedef struct {
    BYTE original[5];
    DWORD target;
} InlineHook;

static BOOL InstallInlineHook(DWORD target_va, void* hook_func, InlineHook* out) {
    BYTE* target = (BYTE*)target_va;
    DWORD oldProtect;

    memcpy(out->original, target, 5);
    out->target = target_va;

    if (!VirtualProtect(target, 5, PAGE_EXECUTE_READWRITE, &oldProtect)) {
        Log("ERROR: VirtualProtect failed for 0x%08X (err=%d)",
            target_va, GetLastError());
        return FALSE;
    }

    target[0] = 0xE9;
    *(DWORD*)(target + 1) = (DWORD)hook_func - (target_va + 5);

    VirtualProtect(target, 5, oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), target, 5);
    return TRUE;
}

/* --- Inline Lua stack manipulation --- */

static void inline_push_boolean(lua_State* L, int b) {
    typedef struct { int value; int tt; } TValue;
    BYTE* Lp = (BYTE*)L;
    TValue** top_ptr = (TValue**)(Lp + 8);
    TValue* top = *top_ptr;
    top->value = (b != 0);
    top->tt = LUA_TBOOLEAN;
    *top_ptr = top + 1;
}

/* --- Hook functions --- */

static int Hook_IsOnlineConnected(lua_State* L) {
    inline_push_boolean(L, 1);
    return 1;
}

static int Hook_HasPlayerUnlockedCode(lua_State* L) {
    inline_push_boolean(L, 1);
    return 1;
}

static int Hook_IsMatchmakingInternet(lua_State* L) {
    inline_push_boolean(L, 1);
    return 1;
}

/* --- DLL Entry Point --- */

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
    (void)lpvReserved;

    if (fdwReason == DLL_PROCESS_ATTACH) {
        InlineHook hookIsOnline = {0};
        InlineHook hookHasUnlocked = {0};
        InlineHook hookIsMatchmaking = {0};
        BOOL onlineHooked = FALSE;
        BOOL unlockHooked = FALSE;
        BOOL matchHooked = FALSE;

        g_hModule = (HMODULE)hinstDLL;
        DisableThreadLibraryCalls(hinstDLL);

        LogInit();
        Log("net_hooks.asi loaded (PID %d)", GetCurrentProcessId());

        /* Find and hook IsOnlineConnected */
        DWORD str_isonline = FindStringInRdata("IsOnlineConnected");
        if (str_isonline) {
            lua_CFunction origFunc = FindLuaFuncForString(str_isonline);
            if (origFunc) {
                g_origIsOnlineConnected = origFunc;
                onlineHooked = InstallInlineHook((DWORD)origFunc,
                                                 (void*)Hook_IsOnlineConnected, &hookIsOnline);
                Log("IsOnlineConnected: found at 0x%08X, hook=%s",
                    (DWORD)origFunc, onlineHooked ? "OK" : "FAIL");
            } else {
                Log("IsOnlineConnected: string found but func not resolved");
            }
        } else {
            Log("IsOnlineConnected: string not found in .rdata");
        }

        /* Find and hook HasPlayerUnlockedCode */
        DWORD str_hasunlocked = FindStringInRdata("HasPlayerUnlockedCode");
        if (str_hasunlocked) {
            lua_CFunction origFunc = FindLuaFuncForString(str_hasunlocked);
            if (origFunc) {
                g_origHasPlayerUnlockedCode = origFunc;
                unlockHooked = InstallInlineHook((DWORD)origFunc,
                                                 (void*)Hook_HasPlayerUnlockedCode, &hookHasUnlocked);
                Log("HasPlayerUnlockedCode: found at 0x%08X, hook=%s",
                    (DWORD)origFunc, unlockHooked ? "OK" : "FAIL");
            } else {
                Log("HasPlayerUnlockedCode: string found but func not resolved");
            }
        } else {
            Log("HasPlayerUnlockedCode: string not found in .rdata");
        }

        /* Find and hook IsMatchmakingInternet */
        DWORD str_ismatch = FindStringInRdata("IsMatchmakingInternet");
        if (str_ismatch) {
            lua_CFunction origFunc = FindLuaFuncForString(str_ismatch);
            if (origFunc) {
                matchHooked = InstallInlineHook((DWORD)origFunc,
                                               (void*)Hook_IsMatchmakingInternet, &hookIsMatchmaking);
                Log("IsMatchmakingInternet: found at 0x%08X, hook=%s",
                    (DWORD)origFunc, matchHooked ? "OK" : "FAIL");
            } else {
                Log("IsMatchmakingInternet: string found but func not resolved");
            }
        } else {
            Log("IsMatchmakingInternet: string not found in .rdata");
        }

        Log("Hooks: Online=%s Unlock=%s Matchmaking=%s",
            onlineHooked ? "OK" : "FAIL",
            unlockHooked ? "OK" : "FAIL",
            matchHooked ? "OK" : "FAIL");

    } else if (fdwReason == DLL_PROCESS_DETACH) {
        Log("net_hooks.asi unloaded");
        LogClose();
    }
    return TRUE;
}
