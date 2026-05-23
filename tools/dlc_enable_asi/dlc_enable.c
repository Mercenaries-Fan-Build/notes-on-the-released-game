/**
 * dlc_enable.asi — DLC Content Activator for Mercenaries 2: World in Flames
 *
 * Bisection toggles (rebuild after changing; override on gcc command line):
 *
 *   DLC_ENABLE_NO_HOOKS          0  when 1: DllMain log ONLY (zero hooks — bisect baseline)
 *   DLC_ENABLE_MINIMAL_MODE      0  when 1: net hooks ONLY (disables print)
 *   DLC_ENABLE_VZ_LOAD_BOOTSTRAP 0  inject on "Loading vz level with vz masterscript" (preferred)
 *   DLC_ENABLE_BOOTSTRAP         0  inject from Hook_IsOnlineConnected (UNSAFE — shell movies)
 *   DLC_ENABLE_DEFERRED_BOOTSTRAP 0  InitThread after loadMainShell + 120s wait
 *
 * Enable bootstrap at compile time (shell "export" does NOT affect the build):
 *   make dlc-asi-native-bootstrap
 *   make -C tools/dlc_enable_asi mingw EXTRA_CFLAGS="-DDLC_ENABLE_VZ_LOAD_BOOTSTRAP=1"
 *   DLC_ENABLE_CRASH_PATCH       0  code-cave JMP at 0x005AE372 (test before enabling)
 *   DLC_ENABLE_PRINT_HOOK        0  Inline-hook shared stub 0x006D5640 (NOISY — 60+ funcs)
 *   DLC_ENABLE_DEBUG_PRINTF_PATCH 1  Patch Debug.Printf + print luaL_Reg → Hook_LogPrintf
 *   DLC_ENABLE_LUA_LOG_VERBOSE   0  Log all script prints; 0 = skip layer/streaming spam
 *   DLC_ENABLE_NET_HOOKS         1  IsOnlineConnected / HasPlayerUnlockedCode / etc.
 *   DLC_ENABLE_ARENA_TRANSITION  1  Log-triggered SetMasterScriptName("DLC01") on DLC accept
 *
 * Default build: Debug.Printf reg patch + net hooks.
 *   make dlc-asi-native-minimal  — net hooks only (no print patch)
 *   make dlc-asi-native-nohooks  — load log only (no hooks at all)
 *
 * Build: make dlc-asi-native  (or mingw in tools/dlc_enable_asi/)
 *
 * IMPORTANT: cracked EXE only (53,482,288 bytes). All VAs are binary-specific.
 */

#ifndef DLC_ENABLE_NO_HOOKS
#define DLC_ENABLE_NO_HOOKS           0
#endif

#ifndef DLC_ENABLE_MINIMAL_MODE
#define DLC_ENABLE_MINIMAL_MODE       0
#endif

#if DLC_ENABLE_NO_HOOKS
#define DLC_ENABLE_VZ_LOAD_BOOTSTRAP    0
#define DLC_ENABLE_BOOTSTRAP          0
#define DLC_ENABLE_DEFERRED_BOOTSTRAP 0
#define DLC_ENABLE_CRASH_PATCH        0
#define DLC_ENABLE_PRINT_HOOK           0
#define DLC_ENABLE_DEBUG_PRINTF_PATCH   0
#define DLC_ENABLE_LUA_LOG_VERBOSE      0
#define DLC_ENABLE_NET_HOOKS              0
#define DLC_ENABLE_PROBE_GLOBALS          0
#define DLC_ENABLE_ARENA_TRANSITION       0
#define DLC_ENABLE_GLOBAL_CRASH_GUARD     1
#define DLC_ENABLE_SHELL_WATCHDOG         0
#elif DLC_ENABLE_MINIMAL_MODE
#define DLC_ENABLE_VZ_LOAD_BOOTSTRAP    0
#define DLC_ENABLE_BOOTSTRAP          0
#define DLC_ENABLE_DEFERRED_BOOTSTRAP 0
#define DLC_ENABLE_CRASH_PATCH        0
#define DLC_ENABLE_PRINT_HOOK           0
#define DLC_ENABLE_DEBUG_PRINTF_PATCH   0
#define DLC_ENABLE_LUA_LOG_VERBOSE        0
#define DLC_ENABLE_NET_HOOKS              1
#define DLC_ENABLE_PROBE_GLOBALS          0
#define DLC_ENABLE_ARENA_TRANSITION       0
#define DLC_ENABLE_GLOBAL_CRASH_GUARD     1
#define DLC_ENABLE_SHELL_WATCHDOG         0
#else
#ifndef DLC_ENABLE_VZ_LOAD_BOOTSTRAP
#define DLC_ENABLE_VZ_LOAD_BOOTSTRAP  0
#endif
#ifndef DLC_ENABLE_BOOTSTRAP
#define DLC_ENABLE_BOOTSTRAP          0
#endif
#ifndef DLC_ENABLE_DEFERRED_BOOTSTRAP
#define DLC_ENABLE_DEFERRED_BOOTSTRAP 0
#endif
#ifndef DLC_ENABLE_CRASH_PATCH
#define DLC_ENABLE_CRASH_PATCH        0
#endif
#ifndef DLC_ENABLE_PRINT_HOOK
#define DLC_ENABLE_PRINT_HOOK         0
#endif
#ifndef DLC_ENABLE_DEBUG_PRINTF_PATCH
#define DLC_ENABLE_DEBUG_PRINTF_PATCH 1
#endif
#ifndef DLC_ENABLE_LUA_LOG_VERBOSE
#define DLC_ENABLE_LUA_LOG_VERBOSE    0
#endif
#ifndef DLC_ENABLE_NET_HOOKS
#define DLC_ENABLE_NET_HOOKS          1
#endif
#ifndef DLC_ENABLE_PROBE_GLOBALS
#define DLC_ENABLE_PROBE_GLOBALS      0
#endif
#ifndef DLC_ENABLE_ARENA_TRANSITION
#define DLC_ENABLE_ARENA_TRANSITION   1
#endif
#ifndef DLC_ENABLE_GLOBAL_CRASH_GUARD
#define DLC_ENABLE_GLOBAL_CRASH_GUARD 1
#endif
#ifndef DLC_ENABLE_SHELL_WATCHDOG
#define DLC_ENABLE_SHELL_WATCHDOG     1
#endif
#endif /* DLC_ENABLE_NO_HOOKS / MINIMAL_MODE / default */

/* PROBE_GLOBALS replaces bootstrap Lua only; VZ-load trigger unchanged. */

#define LUA_LOG_FLUSH_INTERVAL_LINES  64
#define LUA_LOG_FLUSH_INTERVAL_MS     500

/* Deferred bootstrap: require loadMainShell seen AND this minimum wait. */
#define DEFERRED_BOOTSTRAP_MIN_MS  (120 * 1000)
#define DEFERRED_BOOTSTRAP_MAX_MS  (180 * 1000)
/* VZ-load: inject AFTER layer loading and initial mission setup complete.
 * 8s was too early — import("dlc01") re-entered the asset system during
 * 408-layer load, causing a freeze.  60s is safe: layer load + mission
 * unlock + save restore all finish within ~45s on typical hardware. */
#define VZ_LOAD_BOOTSTRAP_DELAY_MS   60000
/* Post-Shell-exited watchdog: log every N ms until crash or timeout. */
#define SHELL_WATCHDOG_INTERVAL_MS   50
#define SHELL_WATCHDOG_MAX_MS        30000
/* Unlock only after "Setting flow data" — MrxMissionFlow.Reset sets _oParent. */
#define FLOW_INIT_UNLOCK_DELAY_MS    5000
#define HOOK_PRINT_MAX_ARGS        32

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

/* --------------------------------------------------------------------------
 * Verified addresses from binary analysis (Agents A/B/C cross-verified).
 *
 * These are HARDCODED for the cracked retail EXE (53,482,288 bytes).
 * The Lua C API in this binary uses LTCG (link-time code generation)
 * calling conventions — parameters passed in registers + stack.
 *
 * The luaB_* wrappers are standard cdecl lua_CFunction entries.
 * -------------------------------------------------------------------------- */

#define EXPECTED_EXE_SIZE   53482288

/* Section layout */
#define RDATA_START_VA      0x00B05000
#define RDATA_SIZE          0x000F1000
#define TEXT_START_VA       0x00401000
#define TEXT_SIZE           0x00703000

/* luaB_* wrappers — standard cdecl: int func(lua_State* L)
 * These read/write args via the Lua stack. */
#define VA_LUAB_LOADSTRING  0x00860FC0
#define VA_LUAB_PCALL       0x008615F0

/* Raw Lua C API — LTCG calling conventions (verified from luaB_loadstring call site).
 *
 * luaL_loadbuffer (0x00860240):
 *   EAX = name (const char* — chunk name)
 *   EDX = L (lua_State*)
 *   Stack arg 1 = buff (const char* — source buffer)
 *   Stack arg 2 = sz (size_t — buffer length)
 *   Caller cleans: ADD ESP, 8
 *   Returns: EAX = status (0 = LUA_OK)
 *
 * lua_pcall (0x0085DF50):
 *   EAX = L (lua_State*)
 *   ECX = errfunc (int — 0 for no error handler)
 *   EDI = nresults (int — 0, or -1 for LUA_MULTRET)
 *   Stack arg 1 = nargs (int)
 *   Caller cleans: ADD ESP, 4
 *   Returns: EAX = status (0 = LUA_OK)
 */
#define VA_LUAL_LOADBUFFER  0x00860240
#define VA_LUA_PCALL        0x0085DF50
#define VA_LUAB_SETFENV     0x008607E0  /* db_setfenv — cdecl lua_CFunction */

/* lua_State::l_gt (TValue {value, tt}) — probe default offset 68; scan if inject-time layout shifts */
#define LUA_STATE_OFF_L_GT_PROBE  68
#define LUA_STATE_L_GT_SCAN_MIN   52
#define LUA_STATE_L_GT_SCAN_MAX   96
#define LUA_TTABLE                5

/* Previously misidentified VAs (kept for documentation / cross-reference) */
#define VA_LUAL_TYPERROR    0x0085F050  /* was wrongly labeled luaL_loadbuffer */
#define VA_LUAD_PCALL       0x00868AD0  /* was wrongly labeled lua_pcall */

/* Lua 5.1 constants */
#define LUA_TBOOLEAN    1
#define LUA_TNUMBER     3
#define LUA_TSTRING     4
#define LUA_OK          0

/* Shared PC stub (33 C0 C3 — xor eax,eax; ret) used by print, Debug.Printf, etc. */
#define VA_PRINT_STUB                 0x006D5640

/* luaL_Reg func pointer slots in .rdata (cracked EXE 53,482,288 bytes) */
#define VA_DEBUG_TABLE                0x00B98828
#define VA_DEBUG_PRINTF_FUNC_PTR      (VA_DEBUG_TABLE + 4)
#define VA_BASE_PRINT_FUNC_PTR        0x00B9251C  /* luaopen_base "print" entry */
#define VA_SYS_WRITETOCONSOLE_FUNC_PTR 0x00B98A7C /* first Sys entry — verify with debug_binding_report.py */

/* --- Forward declarations --- */

typedef void* lua_State;
typedef int (*lua_CFunction)(lua_State* L);

/* --- Global state --- */

static HMODULE g_hModule = NULL;
static lua_CFunction g_origIsOnlineConnected = NULL;
static lua_CFunction g_origHasPlayerUnlockedCode = NULL;
static volatile lua_State* g_capturedState = NULL;
static volatile LONG g_dlcBootstrapDone = 0;
static volatile LONG g_dlcBootstrapOk = 0;
static volatile LONG g_dlcDataRegistered = 0;

/* VZ (60s): import dlc01 + tMissionData only. Late (90s): UnlockMission only. */
#define DLC_BOOT_MODE_VZ    0
#define DLC_BOOT_MODE_LATE  1
#define DLC_BOOT_MODE_FULL  2
static volatile LONG g_shellReady = 0;
static volatile LONG g_inPrintHook = 0;
/* Fire TryDLCBootstrap from print hook (game Lua thread), not CreateThread. */
static volatile DWORD g_pendingVzBootstrapAt = 0;
static volatile DWORD g_pendingLateBootstrapAt = 0;
static volatile LONG g_flowDataReady = 0;
static volatile LONG g_shellExitWatchdogStarted = 0;
static BOOL g_exeVerified = FALSE;

/* --- Arena transition state (DLC_ENABLE_ARENA_TRANSITION) --- */
#if DLC_ENABLE_ARENA_TRANSITION
static volatile LONG g_dlcMissionAccepted = 0;
static volatile LONG g_arenaTransitionFired = 0;
static volatile LONG g_sysSetMasterScriptExists = -1; /* -1=unchecked, 0=no, 1=yes */
static char g_acceptedDlcMission[32] = {0};
/* Delay after mission acceptance before firing SetMasterScriptName.
 * Gives the engine time to finish the PMC interior exit sequence. */
#define ARENA_TRANSITION_DELAY_MS  3000
static volatile DWORD g_pendingArenaTransitionAt = 0;
#endif

/* --- Logging --- */

#define DLC_LOG_SOURCE "dlc_enable"

typedef void (*pfn_pmc_log)(const char *source, const char *fmt, ...);
static pfn_pmc_log g_pmc_log = NULL;
static HANDLE  g_fallbackLog = INVALID_HANDLE_VALUE;
static char    g_fallbackPath[MAX_PATH] = {0};
static HANDLE  g_crashLog = INVALID_HANDLE_VALUE;
static DWORD   g_crashLogLinesSinceFlush = 0;
static DWORD   g_crashLogLastFlushTick = 0;

static void CrashLogMaybeFlush(void) {
    DWORD now;
    if (g_crashLog == INVALID_HANDLE_VALUE) {
        return;
    }
    now = GetTickCount();
    if (g_crashLogLinesSinceFlush >= LUA_LOG_FLUSH_INTERVAL_LINES ||
        (g_crashLogLastFlushTick != 0 &&
         now - g_crashLogLastFlushTick >= LUA_LOG_FLUSH_INTERVAL_MS)) {
        FlushFileBuffers(g_crashLog);
        g_crashLogLinesSinceFlush = 0;
        g_crashLogLastFlushTick = now;
    }
}

static void LogInit(void) {
    HMODULE hBlackbox = GetModuleHandleA("pmc_bb.dll");
    if (hBlackbox) {
        g_pmc_log = (pfn_pmc_log)GetProcAddress(hBlackbox, "pmc_log");
    }
    if (!g_pmc_log) {
        GetModuleFileNameA(g_hModule, g_fallbackPath, MAX_PATH);
        char *dot = strrchr(g_fallbackPath, '.');
        if (dot) strcpy(dot, ".log");
        else strcat(g_fallbackPath, ".log");
        g_fallbackLog = CreateFileA(g_fallbackPath, GENERIC_WRITE, FILE_SHARE_READ,
                                    NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    }

    /* Always write a disk log that survives crashes */
    char crashPath[MAX_PATH];
    GetModuleFileNameA(g_hModule, crashPath, MAX_PATH);
    char *dot2 = strrchr(crashPath, '.');
    if (dot2) strcpy(dot2, "_crash.log");
    else strcat(crashPath, "_crash.log");
    g_crashLog = CreateFileA(crashPath, GENERIC_WRITE, FILE_SHARE_READ,
                             NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
}

static void LogInternal(const char *fmt, va_list ap, BOOL flush_now) {
    char buf[1024];
    int len;

    len = wvsprintfA(buf, fmt, ap);
    if (len <= 0) {
        return;
    }

    if (g_pmc_log) {
        g_pmc_log(DLC_LOG_SOURCE, "%s", buf);
    } else if (g_fallbackLog != INVALID_HANDLE_VALUE) {
        buf[len] = '\r';
        buf[len + 1] = '\n';
        DWORD written;
        WriteFile(g_fallbackLog, buf, len + 2, &written, NULL);
    }

    if (g_crashLog != INVALID_HANDLE_VALUE) {
        buf[len] = '\r';
        buf[len + 1] = '\n';
        DWORD written;
        WriteFile(g_crashLog, buf, len + 2, &written, NULL);
        g_crashLogLinesSinceFlush++;
        if (flush_now) {
            FlushFileBuffers(g_crashLog);
            g_crashLogLinesSinceFlush = 0;
            g_crashLogLastFlushTick = GetTickCount();
        } else {
            CrashLogMaybeFlush();
        }
    }
}

static void Log(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    LogInternal(fmt, ap, TRUE);
    va_end(ap);
}

static void LogNoFlush(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    LogInternal(fmt, ap, FALSE);
    va_end(ap);
}

static void LogClose(void) {
    if (g_crashLog != INVALID_HANDLE_VALUE) {
        FlushFileBuffers(g_crashLog);
    }
    if (g_fallbackLog != INVALID_HANDLE_VALUE) {
        CloseHandle(g_fallbackLog);
        g_fallbackLog = INVALID_HANDLE_VALUE;
    }
    if (g_crashLog != INVALID_HANDLE_VALUE) {
        CloseHandle(g_crashLog);
        g_crashLog = INVALID_HANDLE_VALUE;
    }
}

/* --- EXE verification --- */

static BOOL VerifyExeSize(void) {
    char path[MAX_PATH];
    GetModuleFileNameA(NULL, path, MAX_PATH);
    HANDLE hFile = CreateFileA(path, GENERIC_READ, FILE_SHARE_READ,
                               NULL, OPEN_EXISTING, 0, NULL);
    if (hFile == INVALID_HANDLE_VALUE) return FALSE;
    DWORD size = GetFileSize(hFile, NULL);
    CloseHandle(hFile);
    return (size == EXPECTED_EXE_SIZE);
}

static BOOL IsAddressExecutable(DWORD va) {
    MEMORY_BASIC_INFORMATION mbi;
    if (VirtualQuery((void*)va, &mbi, sizeof(mbi)) == 0) return FALSE;
    return (mbi.State == MEM_COMMIT) &&
           (mbi.Protect & (PAGE_EXECUTE | PAGE_EXECUTE_READ |
                           PAGE_EXECUTE_READWRITE | PAGE_EXECUTE_WRITECOPY));
}

/* --- Memory scanning (for hook installation only) --- */

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

/* --- Custom Lua print() → Log() bridge --- */

/**
 * Replacement for the game's stubbed print() lua_CFunction.
 * Reads all arguments from the Lua stack, concatenates with tabs,
 * and routes through our Log() function → PMC Blackbox console.
 *
 * Lua 5.1.2 (32-bit, float number) internal layout (lstate.h, 32-bit MSVC):
 *   lua_State + 0x08 = StkId top
 *   lua_State + 0x0C = StkId base
 *   lua_State + 0x14 = CallInfo* ci
 *   lua_State + 0x1C = StkId stack_last
 *   lua_State + 0x20 = StkId stack
 *   CallInfo + 0x00 = base, +0x04 = func (C args at func+1 when L->base is stale)
 *   TValue = { DWORD value; DWORD tt; }  (8 bytes)
 *   For tt == LUA_TSTRING: value is TString*
 *   String data starts at TString + 16 (sizeof(TString) in 32-bit Lua 5.1)
 *   For tt == LUA_TNUMBER: value is a float (single-precision in this build)
 *
 * Invalid stack (base=0, top<base, out of [stack,stack_last]): return 0 immediately
 * without touching the stack — same as the game's stub (xor eax,eax; ret).
 */
typedef struct { DWORD value; DWORD tt; } LuaTValue;

#define LUA_STATE_OFF_TOP         0x08
#define LUA_STATE_OFF_BASE        0x0C
#define LUA_STATE_OFF_CI          0x14
#define LUA_STATE_OFF_STACK_LAST  0x1C
#define LUA_STATE_OFF_STACK       0x20
#define CALLINFO_OFF_BASE         0x00
#define CALLINFO_OFF_FUNC         0x04
#define HOOK_PRINT_MAX_STACK_SLOTS 10000

static lua_CFunction g_sysWriteToConsole = NULL;

static BOOL PtrReadable(const void* p, SIZE_T nbytes) {
    MEMORY_BASIC_INFORMATION mbi;
    ULONG_PTR addr;
    ULONG_PTR region_end;

    if (!p || nbytes == 0) return FALSE;
    if (VirtualQuery(p, &mbi, sizeof(mbi)) == 0) return FALSE;
    if (mbi.State != MEM_COMMIT) return FALSE;
    if (mbi.Protect & (PAGE_NOACCESS | PAGE_GUARD)) return FALSE;

    addr = (ULONG_PTR)p;
    region_end = (ULONG_PTR)mbi.BaseAddress + mbi.RegionSize;
    if (addr + nbytes > region_end) return FALSE;

    switch (mbi.Protect & 0xFF) {
        case PAGE_READONLY:
        case PAGE_READWRITE:
        case PAGE_WRITECOPY:
        case PAGE_EXECUTE_READ:
        case PAGE_EXECUTE_READWRITE:
        case PAGE_EXECUTE_WRITECOPY:
            return TRUE;
        default:
            return FALSE;
    }
}

/* Copy Lua TString payload (+16); guard reads — precache print() can pass bad pointers. */
static int SafeCopyTString(DWORD tstring_val, char* out, int out_max) {
    const char* str;
    int slen;

    if (!tstring_val || out_max <= 1) return 0;
    if (!PtrReadable((void*)tstring_val, 20)) {
        strncpy(out, "(bad string)", out_max - 1);
        out[out_max - 1] = '\0';
        return 0;
    }

    str = (const char*)((BYTE*)tstring_val + 16);
    if (!PtrReadable(str, 1)) {
        strncpy(out, "(bad string)", out_max - 1);
        out[out_max - 1] = '\0';
        return 0;
    }

    slen = 0;
    while (slen < out_max - 1) {
        if (!PtrReadable(str + slen, 1)) break;
        if (!str[slen]) break;
        out[slen] = str[slen];
        slen++;
    }
    out[slen] = '\0';
    return slen;
}

static BOOL StkInRange(LuaTValue* p, LuaTValue* stack, LuaTValue* stack_last) {
    return p && stack && stack_last && stack <= stack_last &&
           p >= stack && p <= stack_last;
}

/* Resolve top/base and verify they lie in [stack, stack_last] with sane nargs. */
static BOOL ResolvePrintStack(lua_State* L, LuaTValue** out_top, LuaTValue** out_base, int* out_nargs) {
    BYTE* Lp = (BYTE*)L;
    LuaTValue* top;
    LuaTValue* base;
    LuaTValue* stack;
    LuaTValue* stack_last;
    int nargs;

    if (!PtrReadable(Lp + LUA_STATE_OFF_STACK, sizeof(LuaTValue*) * 3)) {
        return FALSE;
    }

    top        = *(LuaTValue**)(Lp + LUA_STATE_OFF_TOP);
    base       = *(LuaTValue**)(Lp + LUA_STATE_OFF_BASE);
    stack_last = *(LuaTValue**)(Lp + LUA_STATE_OFF_STACK_LAST);
    stack      = *(LuaTValue**)(Lp + LUA_STATE_OFF_STACK);

    if (!StkInRange(stack, stack, stack_last)) {
        return FALSE;
    }

    if (!StkInRange(top, stack, stack_last)) {
        return FALSE;
    }

    if (!StkInRange(base, stack, stack_last)) {
        /* L->base can be 0 during VM transitions; try ci->func+1 (C precall layout). */
        if (PtrReadable(Lp + LUA_STATE_OFF_CI, sizeof(void*))) {
            BYTE* ci = *(BYTE**)(Lp + LUA_STATE_OFF_CI);
            if (ci && PtrReadable(ci + CALLINFO_OFF_FUNC, sizeof(LuaTValue*))) {
                LuaTValue* func = *(LuaTValue**)(ci + CALLINFO_OFF_FUNC);
                if (StkInRange(func, stack, stack_last)) {
                    base = func + 1;
                } else if (PtrReadable(ci + CALLINFO_OFF_BASE, sizeof(LuaTValue*))) {
                    LuaTValue* ci_base = *(LuaTValue**)(ci + CALLINFO_OFF_BASE);
                    if (StkInRange(ci_base, stack, stack_last)) {
                        base = ci_base;
                    }
                }
            }
        }
    }

    if (!StkInRange(base, stack, stack_last)) {
        return FALSE;
    }
    if (top < base) {
        return FALSE;
    }
    if (((ULONG_PTR)base & 3) != 0 || ((ULONG_PTR)top & 3) != 0) {
        return FALSE;
    }
    if (((ULONG_PTR)base - (ULONG_PTR)stack) % sizeof(LuaTValue) != 0 ||
        ((ULONG_PTR)top - (ULONG_PTR)stack) % sizeof(LuaTValue) != 0) {
        return FALSE;
    }

    nargs = (int)(top - base);
    if (nargs <= 0 || nargs > HOOK_PRINT_MAX_ARGS) {
        return FALSE;
    }
    if ((ULONG)nargs > HOOK_PRINT_MAX_STACK_SLOTS) {
        return FALSE;
    }
    if (!PtrReadable(base, (SIZE_T)nargs * sizeof(LuaTValue))) {
        return FALSE;
    }

    *out_top = top;
    *out_base = base;
    *out_nargs = nargs;
    return TRUE;
}

/* High-volume WAD layer streaming — skip unless DLC_ENABLE_LUA_LOG_VERBOSE. */
static BOOL ShouldSkipLuaLogLine(const char* msg) {
#if DLC_ENABLE_LUA_LOG_VERBOSE
    (void)msg;
    return FALSE;
#else
    static const char* const kSkipPrefixes[] = {
        "Loading vz_",
        "Request fulfilled: Load layer",
        "Layer request ",
        "Culling op for layer",
        "(nPendingOps =",
        "AssetOpComplete:",
        "Submitted request for ",
        "Added request ",
    };
    int i;

    if (!msg || !msg[0]) {
        return TRUE;
    }
    for (i = 0; i < (int)(sizeof(kSkipPrefixes) / sizeof(kSkipPrefixes[0])); i++) {
        if (strncmp(msg, kSkipPrefixes[i], strlen(kSkipPrefixes[i])) == 0) {
            return TRUE;
        }
    }
    return FALSE;
#endif
}

static void TryDLCBootstrap(lua_State* L, int boot_mode);
static void LogLuaStackTopError(lua_State* L);
#if DLC_ENABLE_SHELL_WATCHDOG
static void StartShellExitWatchdog(void);
#endif
#if DLC_ENABLE_VZ_LOAD_BOOTSTRAP
static void MaybeRunPendingBootstrap(lua_State* L);
#endif
#if DLC_ENABLE_ARENA_TRANSITION
static void MaybeRunArenaTransition(lua_State* L);
static void TryArenaTransition(lua_State* L);
#endif

/* Debug.Printf / print() replacement — only logs string-first calls (no invalid-stack spam). */
static int Hook_LogPrintf(lua_State* L) {
    if (!L) {
        return 0;
    }

    LuaTValue* top  = NULL;
    LuaTValue* base = NULL;
    int nargs = 0;

    if (!ResolvePrintStack(L, &top, &base, &nargs) || nargs < 1) {
        return 0;
    }

    if (!PtrReadable(base, sizeof(LuaTValue))) {
        return 0;
    }

    LuaTValue first = *base;
    if (first.tt != LUA_TSTRING) {
        return 0;
    }

    if (InterlockedCompareExchange(&g_inPrintHook, 1, 0) != 0) {
        /* Bootstrap probe prints: log without taking the hook lock. */
        char peek[20];
        if (SafeCopyTString(first.value, peek, (int)sizeof(peek)) > 0 &&
            strncmp(peek, "[dlc_enable]", 14) == 0) {
            char probe[512];
            int plen = SafeCopyTString(first.value, probe, (int)sizeof(probe));
            if (plen > 0) {
                LogNoFlush("[lua] %s", probe);
            }
        }
        return 0;
    }

    char buf[2048];
    int pos = 0;

    for (int i = 0; i < nargs && pos < (int)sizeof(buf) - 64; i++) {
        if (i > 0 && pos < (int)sizeof(buf) - 1) {
            buf[pos++] = '\t';
        }

        LuaTValue arg;
        if (!PtrReadable(base + i, sizeof(LuaTValue))) {
            memcpy(buf + pos, "(bad arg)", 9);
            pos += 9;
            continue;
        }
        arg = *(base + i);

        switch (arg.tt) {
            case 0: /* LUA_TNIL */
                memcpy(buf + pos, "nil", 3);
                pos += 3;
                break;
            case LUA_TBOOLEAN: /* 1 */
                if (arg.value) {
                    memcpy(buf + pos, "true", 4); pos += 4;
                } else {
                    memcpy(buf + pos, "false", 5); pos += 5;
                }
                break;
            case 2: /* LUA_TLIGHTUSERDATA */
                pos += wsprintfA(buf + pos, "lightuserdata:0x%08X", arg.value);
                break;
            case LUA_TNUMBER: { /* 3 */
                float fval;
                memcpy(&fval, &arg.value, sizeof(float));
                if (fval == (float)(int)fval && fval > -100000 && fval < 100000) {
                    pos += wsprintfA(buf + pos, "%d", (int)fval);
                } else {
                    pos += wsprintfA(buf + pos, "%f", (double)fval);
                }
                break;
            }
            case LUA_TSTRING: { /* 4 */
                char chunk[256];
                int slen = SafeCopyTString(arg.value, chunk, (int)sizeof(chunk));
                if (slen > 0) {
                    int remaining = (int)sizeof(buf) - pos - 1;
                    if (slen > remaining) slen = remaining;
                    memcpy(buf + pos, chunk, slen);
                    pos += slen;
                } else if (!arg.value) {
                    memcpy(buf + pos, "(null string)", 13); pos += 13;
                } else {
                    memcpy(buf + pos, "(bad string)", 12); pos += 12;
                }
                break;
            }
            case 5: /* LUA_TTABLE */
                pos += wsprintfA(buf + pos, "table:0x%08X", arg.value);
                break;
            case 6: /* LUA_TFUNCTION */
                pos += wsprintfA(buf + pos, "function:0x%08X", arg.value);
                break;
            case 7: /* LUA_TUSERDATA */
                pos += wsprintfA(buf + pos, "userdata:0x%08X", arg.value);
                break;
            case 8: /* LUA_TTHREAD */
                pos += wsprintfA(buf + pos, "thread:0x%08X", arg.value);
                break;
            default:
                pos += wsprintfA(buf + pos, "?type%d:0x%08X", arg.tt, arg.value);
                break;
        }
    }

    buf[pos] = '\0';

#if DLC_ENABLE_DEFERRED_BOOTSTRAP
    if (strstr(buf, "loadMainShell")) {
        InterlockedExchange(&g_shellReady, 1);
    }
#endif

    /* Flushed checkpoint — if log shows this but not MrxSoundBootstrap, crash is
     * in native code between shell teardown and sound bootstrap (often vz.wad open). */
    if (strstr(buf, "Shell exited")) {
        Log("Checkpoint: Shell exited (L=0x%08X bootstrap_ok=%d vz_pending=%d)",
            (DWORD)L, (int)g_dlcBootstrapOk,
            (int)InterlockedCompareExchange((LONG*)&g_pendingVzBootstrapAt, 0, 0));
        Log("Expect next: [lua] MrxSoundBootstrap.Init — crash in native gap if missing");
#if DLC_ENABLE_SHELL_WATCHDOG
        StartShellExitWatchdog();
#endif
    }

#if DLC_ENABLE_VZ_LOAD_BOOTSTRAP
    if (!g_dlcBootstrapOk && strstr(buf, "Loading vz level with vz masterscript")) {
        InterlockedCompareExchangePointer((volatile PVOID*)&g_capturedState, L, NULL);
        if (InterlockedCompareExchange((LONG*)&g_pendingVzBootstrapAt, 0, 0) == 0) {
            InterlockedExchange((LONG*)&g_pendingVzBootstrapAt, (LONG)GetTickCount());
            Log("VZ-load bootstrap: scheduled on game thread (L=0x%08X, delay %u ms)",
                (DWORD)L, (unsigned)VZ_LOAD_BOOTSTRAP_DELAY_MS);
        }
    }
    if (!g_dlcBootstrapOk && strstr(buf, "Setting flow data")) {
        InterlockedCompareExchangePointer((volatile PVOID*)&g_capturedState, L, NULL);
        InterlockedExchange(&g_flowDataReady, 1);
        /* Always reschedule — EnterFreeplayMusic may have armed a timer that
         * fires before MrxMissionFlow.Reset (row 12: unlock at +90s, Reset +7s). */
        InterlockedExchange((LONG*)&g_pendingLateBootstrapAt, (LONG)GetTickCount());
        Log("Late bootstrap: scheduled after mission flow init (delay %u ms, unlock only)",
            (unsigned)FLOW_INIT_UNLOCK_DELAY_MS);
    }
#endif

#if DLC_ENABLE_ARENA_TRANSITION
    /* Detect DLC mission acceptance from log output.
     *
     * Known patterns that indicate a DLC mission was accepted:
     * - "_sSelectedMission = DlcCon" — mission selection in briefing flow
     * - "Task \"Missions.DlcCon" ... "complete" — briefing task done
     * - "Dynamically imported module dlccon" — contract about to load (too late?)
     *
     * We fire on _sSelectedMission which appears BEFORE the briefing completes,
     * giving us maximum lead time before the contract script loads.
     * Also fire on the "Briefing" task complete as a fallback.
     */
    if (!g_arenaTransitionFired && g_dlcBootstrapOk) {
        const char* sel_match = strstr(buf, "_sSelectedMission = DlcCon");
        const char* briefing_match = NULL;
        if (!sel_match) {
            /* Fallback: briefing task completion */
            briefing_match = strstr(buf, "Missions.DlcCon");
            if (briefing_match && !strstr(buf, "complete")) {
                briefing_match = NULL;
            }
        }
        if (sel_match || briefing_match) {
            /* Extract the mission name for logging */
            const char* src = sel_match ? sel_match + 22 : buf; /* skip "_sSelectedMission = " */
            int i;
            if (sel_match) {
                /* Parse: "_sSelectedMission = DlcConXXX" */
                src = sel_match + strlen("_sSelectedMission = ");
                for (i = 0; i < 30 && src[i] && src[i] != '\t' &&
                     src[i] != '\n' && src[i] != ' '; i++) {
                    g_acceptedDlcMission[i] = src[i];
                }
                g_acceptedDlcMission[i] = '\0';
            } else {
                /* Parse from "Missions.DlcConXXX.DlcConXXXBriefing" */
                const char* p = strstr(buf, "Missions.DlcCon");
                if (p) {
                    p += strlen("Missions.");
                    for (i = 0; i < 30 && p[i] && p[i] != '.'; i++) {
                        g_acceptedDlcMission[i] = p[i];
                    }
                    g_acceptedDlcMission[i] = '\0';
                } else {
                    strcpy(g_acceptedDlcMission, "DlcConUnknown");
                }
            }

            if (g_acceptedDlcMission[0] && !g_arenaTransitionFired) {
                InterlockedExchange(&g_dlcMissionAccepted, 1);
                InterlockedExchange((LONG*)&g_pendingArenaTransitionAt, (LONG)GetTickCount());
                Log("[ARENA] DLC mission detected: '%s' — scheduling arena transition (delay %u ms)",
                    g_acceptedDlcMission, (unsigned)ARENA_TRANSITION_DELAY_MS);
            }
        }
    }
#endif

    /* Release before I/O — FlushFileBuffers on every line was freezing layer load. */
    InterlockedExchange(&g_inPrintHook, 0);

#if DLC_ENABLE_VZ_LOAD_BOOTSTRAP
    MaybeRunPendingBootstrap(L);
#endif

#if DLC_ENABLE_ARENA_TRANSITION
    MaybeRunArenaTransition(L);
#endif

    if (!ShouldSkipLuaLogLine(buf)) {
        LogNoFlush("[lua] %s", buf);
    }
    return 0;
}

/* --- Hook functions --- */

static int Hook_IsOnlineConnected(lua_State* L) {
    if (g_capturedState == NULL) {
        InterlockedCompareExchangePointer((volatile PVOID*)&g_capturedState, L, NULL);
        if (g_capturedState == L) {
            Log("Captured lua_State*: 0x%08X", (DWORD)L);
#if DLC_ENABLE_BOOTSTRAP
            /* UNSAFE during ShellBootstrap — enable only for bisection */
            TryDLCBootstrap(L, DLC_BOOT_MODE_FULL);
            Log("Hook_IsOnlineConnected: returned from bootstrap");
#endif
        }
    }
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

static InlineHook g_hookPrint = {0};

/* Patch a luaL_Reg {name, func} func pointer in .rdata (4 bytes). */
static BOOL PatchLuaRegFuncPtr(DWORD reg_func_ptr_va, lua_CFunction new_func, DWORD* out_old_func) {
    DWORD* site;
    DWORD old_val;
    DWORD old_prot;

    if (!new_func || !reg_func_ptr_va) {
        return FALSE;
    }
    site = (DWORD*)reg_func_ptr_va;
    if (!PtrReadable(site, sizeof(DWORD))) {
        return FALSE;
    }
    old_val = *site;
    if (out_old_func) {
        *out_old_func = old_val;
    }
    if (!VirtualProtect(site, sizeof(DWORD), PAGE_READWRITE, &old_prot)) {
        Log("ERROR: VirtualProtect failed for reg ptr 0x%08X (err=%d)",
            reg_func_ptr_va, GetLastError());
        return FALSE;
    }
    *site = (DWORD)new_func;
    VirtualProtect(site, sizeof(DWORD), old_prot, &old_prot);
    return TRUE;
}

static BOOL VerifyRegPointsAtStub(DWORD reg_func_ptr_va) {
    DWORD func_va;
    BYTE* code;

    if (!PtrReadable((void*)reg_func_ptr_va, sizeof(DWORD))) {
        return FALSE;
    }
    func_va = *(DWORD*)reg_func_ptr_va;
    if (func_va != VA_PRINT_STUB) {
        return FALSE;
    }
    code = (BYTE*)func_va;
    if (!PtrReadable(code, 3)) {
        return FALSE;
    }
    return code[0] == 0x33 && code[1] == 0xC0 && code[2] == 0xC3;
}

static void ProbeSysWriteToConsole(void) {
    DWORD func_va;

    if (!PtrReadable((void*)VA_SYS_WRITETOCONSOLE_FUNC_PTR, sizeof(DWORD))) {
        return;
    }
    func_va = *(DWORD*)VA_SYS_WRITETOCONSOLE_FUNC_PTR;
    if (!func_va || func_va == VA_PRINT_STUB) {
        Log("Sys.WriteToConsole: stub or unreadable (0x%08X)", func_va);
        return;
    }
    if (!IsAddressExecutable(func_va)) {
        Log("Sys.WriteToConsole @ 0x%08X (not executable?)", func_va);
        return;
    }
    g_sysWriteToConsole = (lua_CFunction)func_va;
    Log("Sys.WriteToConsole @ 0x%08X (real impl — not hooked)", func_va);
}

/* --- Lua API calls via inline asm (LTCG calling conventions) --- */

/**
 * Call luaL_loadbuffer at VA 0x00860240.
 *
 * Verified calling convention (from luaB_loadstring at 0x00861043):
 *   EAX = name (const char* — chunk name)
 *   EDX = L (lua_State*)
 *   Stack [esp+0] = buff (const char* — source buffer)
 *   Stack [esp+4] = sz (size_t — buffer length)
 *   Caller cleans stack (ADD ESP, 8).
 *   Returns status in EAX (0 = LUA_OK).
 */
static int call_luaL_loadbuffer(lua_State* L, const char* code, size_t len, const char* name) {
    int result;
    volatile DWORD _L = (DWORD)L;
    volatile DWORD _code = (DWORD)code;
    volatile DWORD _len = (DWORD)len;
    volatile DWORD _name = (DWORD)name;
    volatile DWORD _fn = VA_LUAL_LOADBUFFER;

    __asm__ __volatile__ (
        "movl %[name_], %%eax\n\t"  /* EAX = name */
        "movl %[L_], %%edx\n\t"     /* EDX = L */
        "movl %[len_], %%ecx\n\t"   /* ECX = len (temp) */
        "movl %[code_], %%esi\n\t"  /* ESI = code (temp) */
        "movl %[fn_], %%edi\n\t"    /* EDI = fn addr (temp) */
        "pushl %%ecx\n\t"           /* stack arg 2: sz */
        "pushl %%esi\n\t"           /* stack arg 1: buff */
        "call *%%edi\n\t"           /* call through register — no ESP issues */
        "addl $8, %%esp\n\t"
        : "=a" (result)
        : [L_] "m" (_L),
          [code_] "m" (_code),
          [len_] "m" (_len),
          [name_] "m" (_name),
          [fn_] "m" (_fn)
        : "ecx", "edx", "edi", "esi", "memory"
    );
    return result;
}

/**
 * Call lua_pcall at VA 0x0085DF50 with nargs=0, nresults=0, errfunc=0.
 *
 * Verified calling convention:
 *   EAX = L (lua_State*)
 *   ECX = errfunc (int — 0 for no error handler)
 *   EDI = nresults (int — 0)
 *   Stack [esp+0] = nargs (int — 0)
 *   Caller cleans stack (ADD ESP, 4).
 *   Returns status in EAX (0 = LUA_OK).
 */
static int call_lua_pcall_simple(lua_State* L) {
    int result;
    volatile DWORD _L = (DWORD)L;
    volatile DWORD _fn = VA_LUA_PCALL;

    __asm__ __volatile__ (
        "movl %[L_], %%eax\n\t"     /* EAX = L */
        "movl %[fn_], %%esi\n\t"    /* ESI = fn addr (temp) */
        "pushl $0\n\t"               /* stack arg: nargs = 0 */
        "xorl %%ecx, %%ecx\n\t"     /* ECX = errfunc = 0 */
        "xorl %%edi, %%edi\n\t"     /* EDI = nresults = 0 */
        "call *%%esi\n\t"            /* call through register */
        "addl $4, %%esp\n\t"
        : "=a" (result)
        : [L_] "m" (_L),
          [fn_] "m" (_fn)
        : "ecx", "edx", "edi", "esi", "memory"
    );
    return result;
}

static int call_luaB_setfenv(lua_State* L) {
    typedef int (*lua_CFunction)(lua_State* L);
    lua_CFunction fn = (lua_CFunction)VA_LUAB_SETFENV;
    return fn(L);
}

static BOOL LooksLikeGcTable(DWORD ptr) {
    BYTE* p;
    if (!ptr || ptr < 0x00010000u) {
        return FALSE;
    }
    if (!PtrReadable((void*)ptr, 8)) {
        return FALSE;
    }
    p = (BYTE*)ptr;
    /* GCObject: next(4), tt(1), marked(1) — Lua 5.1 table tag is 5 */
    return p[4] == LUA_TTABLE;
}

static BOOL ReadTValueAt(lua_State* L, int off, LuaTValue* out) {
    BYTE* Lp = (BYTE*)L;
    if (!Lp || !out || off < 0) {
        return FALSE;
    }
    if (!PtrReadable(Lp + off, sizeof(LuaTValue))) {
        return FALSE;
    }
    *out = *(LuaTValue*)(Lp + off);
    return TRUE;
}

static BOOL FindThreadGlobalsTValue(lua_State* L, LuaTValue* out, int* found_off) {
    int off;
    LuaTValue tv;

    if (found_off) {
        *found_off = -1;
    }
    if (!L || !out) {
        return FALSE;
    }

    if (ReadTValueAt(L, LUA_STATE_OFF_L_GT_PROBE, &tv) &&
        tv.tt == LUA_TTABLE && LooksLikeGcTable(tv.value)) {
        *out = tv;
        if (found_off) {
            *found_off = LUA_STATE_OFF_L_GT_PROBE;
        }
        return TRUE;
    }

    for (off = LUA_STATE_L_GT_SCAN_MIN; off <= LUA_STATE_L_GT_SCAN_MAX; off += 4) {
        if (off == LUA_STATE_OFF_L_GT_PROBE) {
            continue;
        }
        if (!ReadTValueAt(L, off, &tv)) {
            continue;
        }
        if (tv.tt == LUA_TTABLE && LooksLikeGcTable(tv.value)) {
            *out = tv;
            if (found_off) {
                *found_off = off;
            }
            return TRUE;
        }
    }
    return FALSE;
}

static void inline_push_tvalue(lua_State* L, const LuaTValue* tv) {
    BYTE* Lp = (BYTE*)L;
    LuaTValue** top_ptr = (LuaTValue**)(Lp + LUA_STATE_OFF_TOP);
    LuaTValue* top = *top_ptr;
    *top = *tv;
    *top_ptr = top + 1;
}

static void inline_pop_stack(lua_State* L, int count) {
    BYTE* Lp = (BYTE*)L;
    LuaTValue** top_ptr = (LuaTValue**)(Lp + LUA_STATE_OFF_TOP);
    *top_ptr -= count;
}

/* Slots between base and top (print hook leaves layer strings here). */
static int StackSlotCount(lua_State* L) {
    BYTE* Lp = (BYTE*)L;
    LuaTValue* top;
    LuaTValue* base;

    if (!Lp || !PtrReadable(Lp + LUA_STATE_OFF_TOP, sizeof(LuaTValue*) * 2)) {
        return -1;
    }
    top  = *(LuaTValue**)(Lp + LUA_STATE_OFF_TOP);
    base = *(LuaTValue**)(Lp + LUA_STATE_OFF_BASE);
    if (!top || !base || top < base) {
        return 0;
    }
    return (int)(top - base);
}

/* Inject runs inside Hook_LogPrintf; clear print args before loadbuffer/setfenv. */
static void ClearLuaStackToBase(lua_State* L) {
    BYTE* Lp = (BYTE*)L;
    LuaTValue** top_ptr  = (LuaTValue**)(Lp + LUA_STATE_OFF_TOP);
    LuaTValue** base_ptr = (LuaTValue**)(Lp + LUA_STATE_OFF_BASE);
    *top_ptr = *base_ptr;
}

/* Bind inject chunk fenv to L->l_gt (real thread globals), not loadbuffer sandbox. */
static BOOL SetInjectChunkEnvToThreadGlobals(lua_State* L) {
    LuaTValue gt;
    int gt_off = -1;
    LuaTValue probe;

    if (!FindThreadGlobalsTValue(L, &gt, &gt_off)) {
        if (ReadTValueAt(L, LUA_STATE_OFF_L_GT_PROBE, &probe)) {
            Log("DLC bootstrap: l_gt scan failed (probe@%d val=0x%08X tt=%d)",
                LUA_STATE_OFF_L_GT_PROBE, probe.value, probe.tt);
        } else {
            Log("DLC bootstrap: l_gt scan failed (lua_State unreadable at +%d)",
                LUA_STATE_OFF_L_GT_PROBE);
        }
        return FALSE;
    }
    Log("DLC bootstrap: thread globals table 0x%08X (l_gt offset %d)",
        gt.value, gt_off);
    inline_push_tvalue(L, &gt);
    {
        int sf = call_luaB_setfenv(L);
        if (sf != 1) {
            Log("DLC bootstrap: setfenv returned %d (expected 1)", sf);
            inline_pop_stack(L, 1);
            return FALSE;
        }
    }
    /* setfenv returns old env on stack; leave only the function for pcall */
    inline_pop_stack(L, 1);
    Log("DLC bootstrap: setfenv bound inject chunk to thread globals");
    return TRUE;
}

static int RunInjectLuaChunk(lua_State* L, const char* code, const char* chunk_name) {
    size_t code_len = strlen(code);
    int load_result;
    int slots = StackSlotCount(L);

    if (slots > 0) {
        ClearLuaStackToBase(L);
    }

    load_result = call_luaL_loadbuffer(L, code, code_len, chunk_name);
    if (load_result != LUA_OK) {
        return load_result;
    }
    if (!SetInjectChunkEnvToThreadGlobals(L)) {
        return -1;
    }
    return call_lua_pcall_simple(L);
}

/* --- DLC Bootstrap Injection --- */

static void LogLuaStackTopError(lua_State* L) {
    LuaTValue* top = NULL;
    LuaTValue* base = NULL;
    int nargs = 0;
    LuaTValue* err_slot;
    char buf[512];

    if (!L || !ResolvePrintStack(L, &top, &base, &nargs)) {
        Log("DLC bootstrap: could not read lua stack for error message");
        return;
    }
    if (top <= base) {
        Log("DLC bootstrap: empty lua stack after failed pcall");
        return;
    }
    err_slot = top - 1;
    if (err_slot->tt != LUA_TSTRING) {
        Log("DLC bootstrap: lua error slot type=%d (expected string)", err_slot->tt);
        return;
    }
    if (SafeCopyTString(err_slot->value, buf, (int)sizeof(buf)) > 0) {
        Log("DLC bootstrap: lua error: %s", buf);
    } else {
        Log("DLC bootstrap: lua error string unreadable");
    }
}

#if DLC_ENABLE_PROBE_GLOBALS
static const char* DLC_PROBE_LUA =
    "print('[dlc_enable] PROBE type(import)=' .. type(import))\n"
    "print('[dlc_enable] PROBE type(_MODULES)=' .. type(_MODULES))\n";
#endif

/* SEH-like crash guard using vectored exception handling (MinGW-compatible) */
static volatile LONG g_inInjection = 0;

static BOOL IsFatalInjectionException(DWORD code) {
    switch (code) {
    case 0xC0000005u: /* EXCEPTION_ACCESS_VIOLATION */
    case 0xC000001Du: /* EXCEPTION_ILLEGAL_INSTRUCTION */
    case 0xC0000094u: /* EXCEPTION_INT_DIVIDE_BY_ZERO */
    case 0xC0000096u: /* EXCEPTION_PRIV_INSTRUCTION */
    case 0xC00000FDu: /* EXCEPTION_STACK_OVERFLOW */
        return TRUE;
    default:
        /* Ignore DBG_PRINTEXCEPTION_C (0x40010006), breakpoints, etc. */
        return FALSE;
    }
}

static LONG CALLBACK InjectionCrashGuard(PEXCEPTION_POINTERS info) {
    DWORD code;
    DWORD addr;

    if (!g_inInjection || !info || !info->ExceptionRecord) {
        return EXCEPTION_CONTINUE_SEARCH;
    }
    code = info->ExceptionRecord->ExceptionCode;
    if (!IsFatalInjectionException(code)) {
        return EXCEPTION_CONTINUE_SEARCH;
    }
    addr = (DWORD)info->ExceptionRecord->ExceptionAddress;
    Log("DLC bootstrap: CRASH caught (exception 0x%08X at 0x%08X)", code, addr);
    if (addr == 0x005AE372) {
        Log("DLC bootstrap: hit 0x005AE372 — rebuild with CRASH_PATCH=1 (default dlc-asi-native)");
    }
    g_inInjection = 0;
    InterlockedExchange(&g_dlcBootstrapDone, 0);
    return EXCEPTION_EXECUTE_HANDLER;
}

#if DLC_ENABLE_GLOBAL_CRASH_GUARD
static LONG CALLBACK GlobalCrashGuard(PEXCEPTION_POINTERS info) {
    DWORD code;
    DWORD addr;
    DWORD fault_addr = 0;

    if (!info || !info->ExceptionRecord) {
        return EXCEPTION_CONTINUE_SEARCH;
    }
    code = info->ExceptionRecord->ExceptionCode;
    if (!IsFatalInjectionException(code)) {
        return EXCEPTION_CONTINUE_SEARCH;
    }
    addr = (DWORD)info->ExceptionRecord->ExceptionAddress;
    if (code == 0xC0000005u && info->ExceptionRecord->NumberParameters >= 2) {
        fault_addr = (DWORD)info->ExceptionRecord->ExceptionInformation[1];
    }
    Log("FATAL: exception 0x%08X at 0x%08X fault=0x%08X inInjection=%d",
        code, addr, fault_addr, (int)g_inInjection);
    if (addr == 0x005AE372) {
        Log("FATAL: hit 0x005AE372 — try CRASH_PATCH=1 or remove patch WAD scripts_vz");
    }
    FlushFileBuffers(g_crashLog);
    return EXCEPTION_CONTINUE_SEARCH;
}
#endif

#if DLC_ENABLE_SHELL_WATCHDOG
static DWORD WINAPI ShellExitWatchdogThread(LPVOID param) {
    DWORD t0;

    (void)param;
    t0 = GetTickCount();
    Log("Watchdog: started (+0 ms post-Shell-exited)");
    while (1) {
        DWORD elapsed;
        Sleep(SHELL_WATCHDOG_INTERVAL_MS);
        elapsed = GetTickCount() - t0;
        Log("Watchdog: +%u ms post-Shell-exited (still alive)", elapsed);
        if (elapsed >= SHELL_WATCHDOG_MAX_MS) {
            Log("Watchdog: timeout %u ms — no crash detected in window", SHELL_WATCHDOG_MAX_MS);
            break;
        }
    }
    return 0;
}

static void StartShellExitWatchdog(void) {
    HANDLE th;

    if (InterlockedCompareExchange(&g_shellExitWatchdogStarted, 1, 0) != 0) {
        return;
    }
    th = CreateThread(NULL, 0, ShellExitWatchdogThread, NULL, 0, NULL);
    if (th) {
        CloseHandle(th);
    } else {
        Log("Watchdog: CreateThread failed (err=%d)", GetLastError());
    }
}
#endif /* DLC_ENABLE_SHELL_WATCHDOG */

static void TryDLCBootstrap(lua_State* L, int boot_mode) {
    const char* mode_tag;
    BOOL need_import;
    BOOL need_register;
    BOOL need_unlock;
    BOOL import_ok = FALSE;
    int reg_result = LUA_OK;
    int unlock_result = LUA_OK;

    if (InterlockedCompareExchange(&g_dlcBootstrapDone, 1, 0) != 0) {
        return;
    }

    if (!L) {
        InterlockedExchange(&g_dlcBootstrapDone, 0);
        return;
    }

    if (!g_exeVerified) {
        Log("DLC bootstrap: skipped (EXE mismatch)");
        InterlockedExchange(&g_dlcBootstrapDone, 0);
        return;
    }

    if (boot_mode == DLC_BOOT_MODE_LATE) {
        mode_tag = "late";
    } else if (boot_mode == DLC_BOOT_MODE_VZ) {
        mode_tag = "vz";
    } else {
        mode_tag = "full";
    }

    need_import = (boot_mode != DLC_BOOT_MODE_LATE) || !g_dlcDataRegistered;
    need_register = (boot_mode != DLC_BOOT_MODE_LATE) || !g_dlcDataRegistered;
    need_unlock = (boot_mode == DLC_BOOT_MODE_LATE || boot_mode == DLC_BOOT_MODE_FULL);

    Log("DLC bootstrap [%s]: starting (import=%d register=%d unlock=%d)",
        mode_tag, need_import ? 1 : 0, need_register ? 1 : 0, need_unlock ? 1 : 0);

    PVOID veh = AddVectoredExceptionHandler(1, InjectionCrashGuard);
    g_inInjection = 1;

    int slots = StackSlotCount(L);
    if (slots > 0) {
        Log("DLC bootstrap: clearing %d stack slot(s) left by print hook", slots);
        ClearLuaStackToBase(L);
    }

    /* The print hook's lua_State (L) is a child thread whose l_gt may NOT
     * contain game globals like import().  The captured main state
     * (g_capturedState from Hook_IsOnlineConnected) has the real globals.
     * Try running luaL_loadbuffer + pcall WITHOUT setfenv first — if the
     * default env already has import(), great.  If not, try on the captured
     * main state.  If that also fails, skip setfenv entirely to see what
     * default environment luaL_loadbuffer gives us. */
    if (need_import) {
        static const char* DLC_IMPORT_CHUNK = "import(\"dlc01\")\n";
        int result;
        size_t code_len = strlen(DLC_IMPORT_CHUNK);
        int load_result;

        /* Strategy 1: loadbuffer + pcall WITHOUT setfenv on current L.
         * The default env from luaL_loadbuffer is gt(L); if import() is
         * there as a function (not a table), this works. */
        Log("DLC bootstrap: strategy 1 — pcall on hook thread L=0x%08X (no setfenv)",
            (DWORD)L);
        ClearLuaStackToBase(L);
        load_result = call_luaL_loadbuffer(L, DLC_IMPORT_CHUNK, code_len, "=dlc_s1");
        if (load_result == LUA_OK) {
            result = call_lua_pcall_simple(L);
            if (result == LUA_OK) {
                Log("DLC bootstrap: strategy 1 succeeded");
                goto bootstrap_ok;
            }
            Log("DLC bootstrap: strategy 1 pcall failed (code %d)", result);
            LogLuaStackTopError(L);
            ClearLuaStackToBase(L);
        } else {
            Log("DLC bootstrap: strategy 1 loadbuffer failed (%d)", load_result);
        }

        /* Strategy 2: try on the captured MAIN lua_State if different from L. */
        if (g_capturedState && (lua_State*)g_capturedState != L) {
            lua_State* mainL = (lua_State*)g_capturedState;
            Log("DLC bootstrap: strategy 2 — pcall on main state L=0x%08X (no setfenv)",
                (DWORD)mainL);
            ClearLuaStackToBase(mainL);
            load_result = call_luaL_loadbuffer(mainL, DLC_IMPORT_CHUNK, code_len, "=dlc_s2");
            if (load_result == LUA_OK) {
                result = call_lua_pcall_simple(mainL);
                if (result == LUA_OK) {
                    Log("DLC bootstrap: strategy 2 succeeded (main state)");
                    goto bootstrap_ok;
                }
                Log("DLC bootstrap: strategy 2 pcall failed (code %d)", result);
                LogLuaStackTopError(mainL);
                ClearLuaStackToBase(mainL);
            } else {
                Log("DLC bootstrap: strategy 2 loadbuffer failed (%d)", load_result);
            }
        }

        /* Strategy 3: loadbuffer + setfenv(l_gt) + pcall on hook thread (original approach). */
        Log("DLC bootstrap: strategy 3 — pcall with setfenv(l_gt) on L=0x%08X",
            (DWORD)L);
        ClearLuaStackToBase(L);
        result = RunInjectLuaChunk(L, DLC_IMPORT_CHUNK, "=dlc_s3");
        if (result == LUA_OK) {
            Log("DLC bootstrap: strategy 3 succeeded");
            goto bootstrap_ok;
        }
        Log("DLC bootstrap: strategy 3 pcall failed (code %d)", result);
        LogLuaStackTopError(L);

        /* All strategies failed */
        Log("DLC bootstrap [%s]: import(\"dlc01\") failed", mode_tag);
        InterlockedExchange(&g_dlcBootstrapDone, 0);
        ClearLuaStackToBase(L);
        g_inInjection = 0;
        if (veh) RemoveVectoredExceptionHandler(veh);
        return;

    bootstrap_ok:
        import_ok = TRUE;
        Log("DLC bootstrap [%s]: import(\"dlc01\") succeeded", mode_tag);
    } else {
        import_ok = TRUE;
        Log("DLC bootstrap [%s]: skipping import (dlc01 already loaded)", mode_tag);
    }

    ClearLuaStackToBase(L);

    /* ================================================================
     * Post-import environment probe.
     *
     * WHY tMissionData IS NIL IN OUR CONTEXT:
     *
     * The game's import() uses getfenv(2) — the *caller's* environment.
     * When wifmissionflow calls import("wifmissiondata"), the C++
     * _SYS._IMPORT executes wifmissiondata's bytecode in wifmissionflow's
     * module environment.  So `tMissionData = {}` writes to wifmissionflow's
     * fenv, NOT to _G.
     *
     * Our luaL_loadbuffer chunks get l_gt(L) as their default environment,
     * which is the thread's global table — a DIFFERENT table from any
     * module's fenv.  Hence tMissionData is nil here.
     *
     * STRATEGY: Use only globals that ARE in l_gt (import, _MODULES, pairs,
     * print, tostring) to walk the _MODULES table and find the module env
     * that contains tMissionData.  Then set our chunk's env to that table
     * for the registration step.
     * ================================================================ */

    /* Phase 1: Deep environment probe (VZ/full only — skip on late unlock pass). */
    if (boot_mode != DLC_BOOT_MODE_LATE) {
        static const char* DLC_ENV_PROBE =
            "print('[dlc_probe] === Environment probe start ===')\n"
            "local found_env = nil\n"
            "local found_in = nil\n"
            "\n"
            "if _MODULES then\n"
            "    local mod_count = 0\n"
            "    for k, v in pairs(_MODULES) do\n"
            "        mod_count = mod_count + 1\n"
            "        if v and v.tMissionData then\n"
            "            print('[dlc_probe] tMissionData in module: ' .. tostring(k))\n"
            "            found_env = v\n"
            "            found_in = tostring(k)\n"
            "        end\n"
            "        if v and v.UnlockMission then\n"
            "            print('[dlc_probe] UnlockMission in module: ' .. tostring(k))\n"
            "        end\n"
            "    end\n"
            "    print('[dlc_probe] _MODULES total: ' .. tostring(mod_count))\n"
            "else\n"
            "    print('[dlc_probe] _MODULES is NIL')\n"
            "end\n"
            "\n"
            "if _G and _G.tMissionData then\n"
            "    found_env = _G\n"
            "    found_in = '_G'\n"
            "    print('[dlc_probe] tMissionData in _G')\n"
            "end\n"
            "\n"
            "if not found_env and getfenv then\n"
            "    local th_env = getfenv(0)\n"
            "    if th_env and th_env.tMissionData then\n"
            "        found_env = th_env\n"
            "        found_in = 'getfenv(0)'\n"
            "        print('[dlc_probe] tMissionData in getfenv(0)')\n"
            "    end\n"
            "end\n"
            "\n"
            "if found_env then\n"
            "    local n = 0\n"
            "    for k, v in pairs(found_env.tMissionData) do n = n + 1 end\n"
            "    print('[dlc_probe] RESULT: tMissionData in ' .. tostring(found_in) .. ' (' .. tostring(n) .. ' entries)')\n"
            "else\n"
            "    print('[dlc_probe] RESULT: tMissionData NOT FOUND')\n"
            "end\n"
            "print('[dlc_probe] === Environment probe end ===')\n";

        int diag_result;
        Log("DLC bootstrap: running environment probe (phase 1)...");
        ClearLuaStackToBase(L);
        diag_result = call_luaL_loadbuffer(L, DLC_ENV_PROBE,
                                           strlen(DLC_ENV_PROBE), "=dlc_env_probe");
        if (diag_result == LUA_OK) {
            diag_result = call_lua_pcall_simple(L);
            if (diag_result != LUA_OK) {
                Log("DLC env probe: pcall failed (%d)", diag_result);
                LogLuaStackTopError(L);
            }
        } else {
            Log("DLC env probe: loadbuffer failed (%d)", diag_result);
        }
        ClearLuaStackToBase(L);
    }

    /* Phase 2: Register DLC missions into tMissionData (no UnlockMission here). */
    if (need_register) {
        static const char* DLC_REGISTER_DATA_ONLY =
            "print('[dlc_reg] === DLC tMissionData registration (data only) ===')\n"
            "if Sys and Sys.AddStringDb then\n"
            "    print('[dlc_reg] Calling Sys.AddStringDb(patch01, dlc01)...')\n"
            "    Sys.AddStringDb('patch01', 'dlc01')\n"
            "    print('[dlc_reg] Sys.AddStringDb returned')\n"
            "elseif AddStringDb then\n"
            "    print('[dlc_reg] Calling AddStringDb(patch01, dlc01)...')\n"
            "    AddStringDb('patch01', 'dlc01')\n"
            "    print('[dlc_reg] AddStringDb returned')\n"
            "else\n"
            "    print('[dlc_reg] AddStringDb unavailable — titles may show as [DlcConNNN.Title]')\n"
            "end\n"
            "local target_env = nil\n"
            "\n"
            "if _MODULES then\n"
            "    for k, v in pairs(_MODULES) do\n"
            "        if v and v.tMissionData then\n"
            "            target_env = v\n"
            "            print('[dlc_reg] Found tMissionData in module: ' .. tostring(k))\n"
            "        end\n"
            "    end\n"
            "end\n"
            "if not target_env and _G and _G.tMissionData then\n"
            "    target_env = _G\n"
            "    print('[dlc_reg] Found tMissionData in _G')\n"
            "end\n"
            "if not target_env and getfenv then\n"
            "    local th = getfenv(0)\n"
            "    if th and th.tMissionData then\n"
            "        target_env = th\n"
            "        print('[dlc_reg] Found tMissionData in getfenv(0)')\n"
            "    end\n"
            "end\n"
            "\n"
            "if target_env and target_env.tMissionData then\n"
            "    local tmd = target_env.tMissionData\n"
            "    local pre_count = 0\n"
            "    for k, v in pairs(tmd) do pre_count = pre_count + 1 end\n"
            "    print('[dlc_reg] tMissionData pre-registration count: ' .. tostring(pre_count))\n"
            "\n"
            "    if tmd['PmcCon031'] then\n"
            "        print('[dlc_reg] Sample PmcCon031 fields:')\n"
            "        for k, v in pairs(tmd['PmcCon031']) do\n"
            "            print('[dlc_reg]   PmcCon031.' .. tostring(k) .. ' = ' .. tostring(v))\n"
            "        end\n"
            "    end\n"
            "\n"
            "    if not tmd['DlcCon001'] then\n"
            "        print('[dlc_reg] Registering DLC missions into tMissionData...')\n"
            "        tmd['DlcCon001'] = {\n"
            "            sModuleName = 'dlccon001',\n"
            "            sFactionId = 'Pmc',\n"
            "            sStarter = 'PmcBoss',\n"
            "            bContract = true,\n"
            "            bCriticalPathMission = false,\n"
            "            bRepeatable = true,\n"
            "            nLevels = 1,\n"
            "            nPdaSortOrder = 100,\n"
            "        }\n"
            "        tmd['DlcCon002'] = {\n"
            "            sModuleName = 'dlccon002',\n"
            "            sFactionId = 'Pmc',\n"
            "            sStarter = 'PmcBoss',\n"
            "            bContract = true,\n"
            "            bCriticalPathMission = false,\n"
            "            bRepeatable = true,\n"
            "            nLevels = 1,\n"
            "            nPdaSortOrder = 101,\n"
            "        }\n"
            "        tmd['DlcCon003'] = {\n"
            "            sModuleName = 'dlccon003',\n"
            "            sFactionId = 'Pmc',\n"
            "            sStarter = 'PmcBoss',\n"
            "            bContract = true,\n"
            "            bCriticalPathMission = false,\n"
            "            bRepeatable = true,\n"
            "            nLevels = 1,\n"
            "            nPdaSortOrder = 102,\n"
            "        }\n"
            "        tmd['DlcCon004a'] = {\n"
            "            sModuleName = 'dlccon004a',\n"
            "            sFactionId = 'Pmc',\n"
            "            sStarter = 'PmcBoss',\n"
            "            bContract = true,\n"
            "            bCriticalPathMission = false,\n"
            "            bRepeatable = true,\n"
            "            nLevels = 1,\n"
            "            nPdaSortOrder = 103,\n"
            "        }\n"
            "        local post_count = 0\n"
            "        for k, v in pairs(tmd) do post_count = post_count + 1 end\n"
            "        print('[dlc_reg] 4 DLC missions registered (count: ' .. tostring(pre_count) .. ' -> ' .. tostring(post_count) .. ')')\n"
            "    else\n"
            "        print('[dlc_reg] DlcCon001 already present — skipping registration')\n"
            "    end\n"
            "else\n"
            "    error('[dlc_reg] tMissionData NOT FOUND in any scope')\n"
            "end\n"
            "print('[dlc_reg] === DLC data registration end (unlock deferred) ===')\n";

        Log("DLC bootstrap [%s]: running tMissionData registration (phase 2)...", mode_tag);
        ClearLuaStackToBase(L);
        reg_result = call_luaL_loadbuffer(L, DLC_REGISTER_DATA_ONLY,
                                          strlen(DLC_REGISTER_DATA_ONLY),
                                          "=dlc_reg_data");
        if (reg_result == LUA_OK) {
            reg_result = call_lua_pcall_simple(L);
            if (reg_result != LUA_OK) {
                Log("DLC registration [%s]: pcall failed (%d)", mode_tag, reg_result);
                LogLuaStackTopError(L);
            }
        } else {
            Log("DLC registration [%s]: loadbuffer failed (%d)", mode_tag, reg_result);
        }
        ClearLuaStackToBase(L);
        if (reg_result != LUA_OK) {
            InterlockedExchange(&g_dlcBootstrapDone, 0);
            g_inInjection = 0;
            if (veh) RemoveVectoredExceptionHandler(veh);
            return;
        }
        InterlockedExchange(&g_dlcDataRegistered, 1);
        Log("DLC bootstrap [%s]: tMissionData registration succeeded", mode_tag);
    }

    /* Phase 2b: UnlockMission via wifmissionflow (late/full only).
     *
     * UnlockMission is inherited from MrxMissionFlow (mrxmissionflow chunk).
     * Its body indexes global _oParent, which is only set after Reset() +
     * SetFlowData — not at EnterFreeplayMusic.  setfenv(1, flow_env) only
     * resolves the function reference; the callee still uses mrxmissionflow
     * fenv unless we setfenv(flow_env.UnlockMission, flow_env).
     *
     * Do NOT call dynamic_import("dlccon*") here — contracts load on accept. */
    if (need_unlock) {
        static const char* DLC_UNLOCK_MISSIONS =
            "print('[dlc_unlock] === DLC unlock (wifmissionflow only) ===')\n"
            "local flow_env = _MODULES and _MODULES.wifmissionflow\n"
            "if not flow_env then\n"
            "    error('[dlc_unlock] wifmissionflow module not found')\n"
            "end\n"
            "if not flow_env.UnlockMission then\n"
            "    error('[dlc_unlock] wifmissionflow.UnlockMission not found')\n"
            "end\n"
            "if not flow_env._oParent then\n"
            "    error('[dlc_unlock] _oParent nil — mission flow not initialized')\n"
            "end\n"
            "print('[dlc_unlock] _oParent ready (post Reset/SetFlowData)')\n"
            "if Sys and Sys.AddStringDb then\n"
            "    print('[dlc_unlock] Calling Sys.AddStringDb(patch01, dlc01)...')\n"
            "    Sys.AddStringDb('patch01', 'dlc01')\n"
            "elseif AddStringDb then\n"
            "    print('[dlc_unlock] Calling AddStringDb(patch01, dlc01)...')\n"
            "    AddStringDb('patch01', 'dlc01')\n"
            "end\n"
            "print('[dlc_unlock] Skipping dynamic_import — contracts load on accept via ASET')\n"
            "\n"
            "local unlock_fn = flow_env.UnlockMission\n"
            "if setfenv then\n"
            "    setfenv(unlock_fn, flow_env)\n"
            "    print('[dlc_unlock] Bound UnlockMission fenv to wifmissionflow')\n"
            "end\n"
            "\n"
            "local missions = {'DlcCon001', 'DlcCon002', 'DlcCon003', 'DlcCon004a'}\n"
            "for _, name in ipairs(missions) do\n"
            "    print('[dlc_unlock] Calling wifmissionflow.UnlockMission(' .. name .. ')...')\n"
            "    unlock_fn(name)\n"
            "    print('[dlc_unlock] UnlockMission(' .. name .. ') returned')\n"
            "end\n"
            "print('[dlc_unlock] 4 DLC missions unlocked via wifmissionflow')\n"
            "\n"
            "local ui_env = _MODULES and _MODULES.wifpmcinterior\n"
            "if ui_env and ui_env.RefreshUiDisplay then\n"
            "    print('[dlc_unlock] Calling wifpmcinterior.RefreshUiDisplay()...')\n"
            "    ui_env.RefreshUiDisplay()\n"
            "    print('[dlc_unlock] RefreshUiDisplay returned')\n"
            "else\n"
            "    print('[dlc_unlock] wifpmcinterior.RefreshUiDisplay not available')\n"
            "end\n"
            "print('[dlc_unlock] === DLC unlock end ===')\n";

        Log("DLC bootstrap [%s]: running UnlockMission (phase 2b, no dynamic_import)...", mode_tag);
        ClearLuaStackToBase(L);
        unlock_result = call_luaL_loadbuffer(L, DLC_UNLOCK_MISSIONS,
                                             strlen(DLC_UNLOCK_MISSIONS),
                                             "=dlc_unlock");
        if (unlock_result == LUA_OK) {
            unlock_result = call_lua_pcall_simple(L);
            if (unlock_result != LUA_OK) {
                Log("DLC unlock [%s]: pcall failed (%d)", mode_tag, unlock_result);
                LogLuaStackTopError(L);
            }
        } else {
            Log("DLC unlock [%s]: loadbuffer failed (%d)", mode_tag, unlock_result);
        }
        ClearLuaStackToBase(L);
        if (unlock_result != LUA_OK) {
            InterlockedExchange(&g_dlcBootstrapDone, 0);
            g_inInjection = 0;
            if (veh) RemoveVectoredExceptionHandler(veh);
            return;
        }
        InterlockedExchange(&g_dlcBootstrapOk, 1);
        Log("DLC bootstrap [%s]: unlock + UI refresh succeeded", mode_tag);
    } else {
        Log("DLC bootstrap [%s]: data registered — unlock deferred to late bootstrap", mode_tag);
    }

    /* Phase 3: Main-state probe removed (was diagnostic-only; info now known). */

    g_inInjection = 0;
    if (veh) RemoveVectoredExceptionHandler(veh);

    if (g_dlcBootstrapOk) {
        Log("DLC bootstrap [%s]: complete (import + register + unlock)", mode_tag);
    } else if (g_dlcDataRegistered) {
        Log("DLC bootstrap [%s]: complete (import + register; awaiting late unlock)", mode_tag);
    } else {
        Log("DLC bootstrap [%s]: finished without registering mission data", mode_tag);
    }
    (void)import_ok;
}

#if DLC_ENABLE_VZ_LOAD_BOOTSTRAP
static void MaybeRunPendingBootstrap(lua_State* L) {
    DWORD now;
    DWORD at;
    DWORD elapsed;

    if (!L || g_dlcBootstrapOk) {
        return;
    }

    now = GetTickCount();

    at = g_pendingVzBootstrapAt;
    if (at != 0) {
        elapsed = now - at;
        if (elapsed >= VZ_LOAD_BOOTSTRAP_DELAY_MS) {
            InterlockedExchange((LONG*)&g_pendingVzBootstrapAt, 0);
            Log("VZ-load bootstrap: running inject on game thread (L=0x%08X)", (DWORD)L);
            TryDLCBootstrap(L, DLC_BOOT_MODE_VZ);
        }
    }

    at = g_pendingLateBootstrapAt;
    if (at != 0 && !g_dlcBootstrapOk && g_flowDataReady) {
        elapsed = now - at;
        if (elapsed >= FLOW_INIT_UNLOCK_DELAY_MS) {
            InterlockedExchange((LONG*)&g_pendingLateBootstrapAt, 0);
            Log("Late bootstrap: running unlock on game thread (L=0x%08X)", (DWORD)L);
            InterlockedExchange(&g_dlcBootstrapDone, 0);
            TryDLCBootstrap(L, DLC_BOOT_MODE_LATE);
        }
    }
}
#endif

#if DLC_ENABLE_ARENA_TRANSITION
/* =========================================================================
 * Arena Transition — Experimental SetMasterScriptName("DLC01") call
 *
 * This is triggered when the log hook detects that a DLC mission has been
 * accepted (pattern: "_sSelectedMission = DlcCon*" or briefing task complete).
 *
 * The transition fires AFTER a short delay to allow the PMC interior exit
 * sequence to complete, but BEFORE the contract script tries to initialize
 * its arena-specific world references.
 *
 * Strategy:
 * 1. Check if Sys.SetMasterScriptName exists (cached after first probe)
 * 2. If yes: call Sys.SetMasterScriptName("DLC01")
 * 3. Log all results for diagnostics
 * 4. If it doesn't exist: try calling it as a top-level function
 * ========================================================================= */

static void TryArenaTransition(lua_State* L) {
    int result;
    PVOID veh;

    if (!L || !g_exeVerified) {
        Log("[ARENA] TryArenaTransition: skipped (L=0x%08X verified=%d)",
            (DWORD)L, g_exeVerified);
        return;
    }

    if (InterlockedCompareExchange(&g_arenaTransitionFired, 1, 0) != 0) {
        return;
    }

    Log("[ARENA] === Arena Transition Start ===");
    Log("[ARENA] Accepted mission: %s", g_acceptedDlcMission);
    Log("[ARENA] L=0x%08X, bootstrap_ok=%d",
        (DWORD)L, (int)g_dlcBootstrapOk);

    veh = AddVectoredExceptionHandler(1, InjectionCrashGuard);
    g_inInjection = 1;

    ClearLuaStackToBase(L);

    /* Phase 1: Probe whether Sys.SetMasterScriptName exists (if not already probed). */
    if (g_sysSetMasterScriptExists < 0) {
        static const char* PROBE_SET_MASTER =
            "if Sys and Sys.SetMasterScriptName then\n"
            "    print('[dlc_arena] Sys.SetMasterScriptName EXISTS: ' .. tostring(Sys.SetMasterScriptName))\n"
            "    if Sys.GetMasterScriptName then\n"
            "        local ok, cur = pcall(Sys.GetMasterScriptName)\n"
            "        if ok then\n"
            "            print('[dlc_arena] Current master script: ' .. tostring(cur))\n"
            "        end\n"
            "    end\n"
            "    if Sys.IsDLC then\n"
            "        local ok2, val = pcall(Sys.IsDLC)\n"
            "        if ok2 then\n"
            "            print('[dlc_arena] IsDLC() = ' .. tostring(val))\n"
            "        end\n"
            "    end\n"
            "    _G._dlc_arena_api_exists = true\n"
            "elseif SetMasterScriptName then\n"
            "    print('[dlc_arena] Top-level SetMasterScriptName: ' .. tostring(SetMasterScriptName))\n"
            "    _G._dlc_arena_api_exists = true\n"
            "else\n"
            "    print('[dlc_arena] SetMasterScriptName NOT FOUND in Sys or top-level')\n"
            "    _G._dlc_arena_api_exists = false\n"
            "end\n";

        Log("[ARENA] Probing Sys.SetMasterScriptName existence...");
        result = call_luaL_loadbuffer(L, PROBE_SET_MASTER,
                                     strlen(PROBE_SET_MASTER), "=arena_probe");
        if (result == LUA_OK) {
            result = call_lua_pcall_simple(L);
            if (result != LUA_OK) {
                Log("[ARENA] Probe pcall failed (code %d)", result);
                LogLuaStackTopError(L);
                InterlockedExchange(&g_sysSetMasterScriptExists, 0);
            } else {
                /* The chunk set _G._dlc_arena_api_exists — we'll check in the next chunk */
                InterlockedExchange(&g_sysSetMasterScriptExists, 1);
            }
        } else {
            Log("[ARENA] Probe loadbuffer failed (%d)", result);
            InterlockedExchange(&g_sysSetMasterScriptExists, 0);
        }
        ClearLuaStackToBase(L);
    }

    /* Phase 2: Call SetMasterScriptName("DLC01").
     *
     * IMPORTANT: This is the speculative/experimental call. We don't know if:
     * - It triggers a full level transition (ideal)
     * - It just sets a variable and does nothing (need supplemental loading)
     * - It crashes (crash guard will catch)
     * - It's a stub/NOP
     *
     * We call it regardless of the probe result — worst case, the Lua call
     * errors out and we log it. */
    {
        static const char* CALL_SET_MASTER =
            "print('[dlc_arena] === Calling SetMasterScriptName(DLC01) ===')\n"
            "local called = false\n"
            "local call_result = nil\n"
            "\n"
            "-- Try Sys.SetMasterScriptName first\n"
            "if Sys and Sys.SetMasterScriptName then\n"
            "    print('[dlc_arena] Calling Sys.SetMasterScriptName(\"DLC01\")...')\n"
            "    local ok, err = pcall(Sys.SetMasterScriptName, 'DLC01')\n"
            "    if ok then\n"
            "        print('[dlc_arena] Sys.SetMasterScriptName(DLC01) returned successfully')\n"
            "        called = true\n"
            "    else\n"
            "        print('[dlc_arena] Sys.SetMasterScriptName FAILED: ' .. tostring(err))\n"
            "    end\n"
            "end\n"
            "\n"
            "-- Fallback: top-level function\n"
            "if not called and SetMasterScriptName then\n"
            "    print('[dlc_arena] Trying top-level SetMasterScriptName(\"DLC01\")...')\n"
            "    local ok, err = pcall(SetMasterScriptName, 'DLC01')\n"
            "    if ok then\n"
            "        print('[dlc_arena] SetMasterScriptName(DLC01) returned successfully')\n"
            "        called = true\n"
            "    else\n"
            "        print('[dlc_arena] SetMasterScriptName FAILED: ' .. tostring(err))\n"
            "    end\n"
            "end\n"
            "\n"
            "if not called then\n"
            "    print('[dlc_arena] WARNING: Could not call SetMasterScriptName — API not found')\n"
            "end\n"
            "\n"
            "-- Post-call diagnostics: check what changed\n"
            "if Sys then\n"
            "    if Sys.GetMasterScriptName then\n"
            "        local ok, name = pcall(Sys.GetMasterScriptName)\n"
            "        if ok then\n"
            "            print('[dlc_arena] After: GetMasterScriptName() = ' .. tostring(name))\n"
            "        end\n"
            "    end\n"
            "    if Sys.IsDLC then\n"
            "        local ok, val = pcall(Sys.IsDLC)\n"
            "        if ok then\n"
            "            print('[dlc_arena] After: IsDLC() = ' .. tostring(val))\n"
            "        end\n"
            "    end\n"
            "    if Sys.DlcMapId then\n"
            "        local ok, val = pcall(Sys.DlcMapId)\n"
            "        if ok then\n"
            "            print('[dlc_arena] After: DlcMapId() = ' .. tostring(val))\n"
            "        end\n"
            "    end\n"
            "end\n"
            "\n"
            "print('[dlc_arena] === SetMasterScriptName experiment complete ===')\n";

        Log("[ARENA] Executing SetMasterScriptName(\"DLC01\") call...");
        ClearLuaStackToBase(L);
        result = call_luaL_loadbuffer(L, CALL_SET_MASTER,
                                     strlen(CALL_SET_MASTER), "=arena_transition");
        if (result == LUA_OK) {
            result = call_lua_pcall_simple(L);
            if (result != LUA_OK) {
                Log("[ARENA] SetMasterScriptName pcall FAILED (code %d)", result);
                LogLuaStackTopError(L);
            } else {
                Log("[ARENA] SetMasterScriptName chunk executed successfully");
            }
        } else {
            Log("[ARENA] SetMasterScriptName loadbuffer failed (%d)", result);
        }
        ClearLuaStackToBase(L);
    }

    g_inInjection = 0;
    if (veh) RemoveVectoredExceptionHandler(veh);

    Log("[ARENA] === Arena Transition End (check logs for engine reaction) ===");
}

static void MaybeRunArenaTransition(lua_State* L) {
    DWORD now;
    DWORD at;
    DWORD elapsed;

    if (!L || !g_dlcMissionAccepted || g_arenaTransitionFired) {
        return;
    }

    at = g_pendingArenaTransitionAt;
    if (at == 0) {
        return;
    }

    now = GetTickCount();
    elapsed = now - at;
    if (elapsed >= ARENA_TRANSITION_DELAY_MS) {
        InterlockedExchange((LONG*)&g_pendingArenaTransitionAt, 0);
        Log("[ARENA] Delay elapsed (%u ms) — firing arena transition on game thread (L=0x%08X)",
            elapsed, (DWORD)L);
        TryArenaTransition(L);
    }
}
#endif /* DLC_ENABLE_ARENA_TRANSITION */

/* --- Init thread (deferred lua_State capture + bootstrap) --- */

static DWORD WINAPI InitThread(LPVOID param) {
    (void)param;

    /* Wait up to 120s for first IsOnlineConnected (captures L, no bootstrap here). */
    for (int wait = 0; wait < 240 && g_capturedState == NULL; wait++) {
        Sleep(500);
    }

#if DLC_ENABLE_DEFERRED_BOOTSTRAP
    if (g_capturedState && !g_dlcBootstrapDone) {
        DWORD t0 = GetTickCount();
        BOOL ready = FALSE;
        while (1) {
            DWORD elapsed = GetTickCount() - t0;
            if (g_shellReady && elapsed >= DEFERRED_BOOTSTRAP_MIN_MS) {
                ready = TRUE;
                break;
            }
            if (elapsed >= DEFERRED_BOOTSTRAP_MAX_MS) {
                Log("Deferred bootstrap: ABORT — loadMainShell not seen within %u s",
                    DEFERRED_BOOTSTRAP_MAX_MS / 1000);
                break;
            }
            Sleep(500);
        }
        if (ready) {
            Log("Deferred bootstrap: ABOUT TO RUN (shellReady=1 waitMs=%u L=0x%08X)",
                GetTickCount() - t0, (DWORD)g_capturedState);
            TryDLCBootstrap((lua_State*)g_capturedState, DLC_BOOT_MODE_FULL);
        }
    }
#elif DLC_ENABLE_BOOTSTRAP
    if (g_capturedState && !g_dlcBootstrapDone) {
        TryDLCBootstrap((lua_State*)g_capturedState, DLC_BOOT_MODE_FULL);
    }
#endif

    if (!g_capturedState) {
        Log("lua_State not captured after 120s; bootstrap skipped");
    }

    LogClose();
    return 0;
}

/* --- DLL Entry Point --- */

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
    (void)lpvReserved;

    if (fdwReason == DLL_PROCESS_ATTACH) {
        InlineHook hookIsOnline = {0};
        InlineHook hookHasUnlocked = {0};
        InlineHook hookIsMatchmaking = {0};

        g_hModule = (HMODULE)hinstDLL;
        DisableThreadLibraryCalls(hinstDLL);

        LogInit();
        Log("dlc_enable.asi loaded (PID %d)", GetCurrentProcessId());
#if DLC_ENABLE_NO_HOOKS
        Log("Build: NO_HOOKS (DllMain log only — zero runtime hooks)");
#elif DLC_ENABLE_MINIMAL_MODE
        Log("Build: MINIMAL (net hooks only, no print patch)");
#elif DLC_ENABLE_PROBE_GLOBALS
        Log("Build: PROBE_GLOBALS=1 VZ_LOAD=%s (type dump at inject)",
            DLC_ENABLE_VZ_LOAD_BOOTSTRAP ? "ON" : "OFF");
#elif DLC_ENABLE_VZ_LOAD_BOOTSTRAP
        Log("Build: VZ_LOAD luaL_loadbuffer+pcall bootstrap (multi-strategy)");
#else
        Log("Build: bootstrap=OFF (net hooks / logging only)");
#endif
        Log("Flags: NO_HOOKS=%d MINIMAL=%d VZ_LOAD=%d BOOTSTRAP=%d DEFERRED=%d CRASH_PATCH=%d STUB_HOOK=%d REG_PATCH=%d LUA_VERBOSE=%d NET=%d ARENA=%d GUARD=%d WATCHDOG=%d",
            DLC_ENABLE_NO_HOOKS, DLC_ENABLE_MINIMAL_MODE, DLC_ENABLE_VZ_LOAD_BOOTSTRAP,
            DLC_ENABLE_BOOTSTRAP, DLC_ENABLE_DEFERRED_BOOTSTRAP,
            DLC_ENABLE_CRASH_PATCH, DLC_ENABLE_PRINT_HOOK, DLC_ENABLE_DEBUG_PRINTF_PATCH,
            DLC_ENABLE_LUA_LOG_VERBOSE, DLC_ENABLE_NET_HOOKS, DLC_ENABLE_ARENA_TRANSITION,
            DLC_ENABLE_GLOBAL_CRASH_GUARD, DLC_ENABLE_SHELL_WATCHDOG);
        if (!DLC_ENABLE_NO_HOOKS && !DLC_ENABLE_VZ_LOAD_BOOTSTRAP &&
            !DLC_ENABLE_BOOTSTRAP && !DLC_ENABLE_DEFERRED_BOOTSTRAP) {
            Log("WARNING: bootstrap OFF — rebuild with: make dlc-asi-native");
        }

#if DLC_ENABLE_GLOBAL_CRASH_GUARD
        if (AddVectoredExceptionHandler(1, GlobalCrashGuard)) {
            Log("Global crash guard installed (logs FATAL AV to dlc_enable_crash.log)");
        }
#endif

#if DLC_ENABLE_NET_HOOKS
        /* Install hooks immediately — .rdata is already mapped */
        DWORD str_isonline = FindStringInRdata("IsOnlineConnected");
        if (str_isonline) {
            lua_CFunction origFunc = FindLuaFuncForString(str_isonline);
            if (origFunc) {
                g_origIsOnlineConnected = origFunc;
                InstallInlineHook((DWORD)origFunc,
                                  (void*)Hook_IsOnlineConnected, &hookIsOnline);
            }
        }

        DWORD str_hasunlocked = FindStringInRdata("HasPlayerUnlockedCode");
        if (str_hasunlocked) {
            lua_CFunction origFunc = FindLuaFuncForString(str_hasunlocked);
            if (origFunc) {
                g_origHasPlayerUnlockedCode = origFunc;
                InstallInlineHook((DWORD)origFunc,
                                  (void*)Hook_HasPlayerUnlockedCode, &hookHasUnlocked);
            }
        }

        DWORD str_ismatch = FindStringInRdata("IsMatchmakingInternet");
        BOOL matchHooked = FALSE;
        if (str_ismatch) {
            lua_CFunction origFunc = FindLuaFuncForString(str_ismatch);
            if (origFunc) {
                InstallInlineHook((DWORD)origFunc,
                                  (void*)Hook_IsMatchmakingInternet, &hookIsMatchmaking);
                matchHooked = TRUE;
            }
        }
#else
        BOOL matchHooked = FALSE;
#endif

        /* Verify EXE matches expected binary */
        g_exeVerified = VerifyExeSize();
        if (!g_exeVerified) {
            Log("WARNING: EXE size mismatch — hardcoded VAs may be wrong, injection disabled");
        }

#if DLC_ENABLE_CRASH_PATCH
        /* ----------------------------------------------------------------
         * Fix crash at VA 0x005AE372: NULL dereference in script command
         * dispatcher. The function loads edi from global [0x01176630] (the
         * script command table) — which may be NULL if the engine hasn't
         * initialized yet when a movie script fires. It then calls a lookup
         * function which returns NULL, and dereferences [esi+0x40] -> crash.
         *
         * Patch: At 0x005AE372, overwrite 9 bytes with a JMP to a code
         * cave that checks for NULL before the dereference.
         * Original: 8B 46 40 8B 71 5C 83 C1 5C (3 MOV/ADD instructions)
         * Patched:  E9 <rel32> 90 90 90 90     (JMP + NOP padding)
         * ---------------------------------------------------------------- */
        if (g_exeVerified) {
            static BYTE s_crashFixCave[] = {
                0x85, 0xF6,                         /* test esi, esi          */
                0x74, 0x0E,                         /* jz .bail (skip 14)     */
                0x8B, 0x46, 0x40,                   /* mov eax, [esi+0x40]    */
                0x8B, 0x71, 0x5C,                   /* mov esi, [ecx+0x5C]    */
                0x83, 0xC1, 0x5C,                   /* add ecx, 0x5C          */
                0xE9, 0x00, 0x00, 0x00, 0x00,       /* jmp back (patched)     */
                /* .bail: */
                0xE9, 0x00, 0x00, 0x00, 0x00,       /* jmp epilogue (patched) */
            };
            /* Allocate executable page for the code cave */
            BYTE *cave = (BYTE*)VirtualAlloc(NULL, 64, MEM_COMMIT | MEM_RESERVE,
                                             PAGE_EXECUTE_READWRITE);
            if (cave) {
                memcpy(cave, s_crashFixCave, sizeof(s_crashFixCave));

                /* Patch 'jmp back' target: return to 0x005AE37B */
                DWORD jmpBackAddr = 0x005AE37B;
                DWORD jmpBackRel = jmpBackAddr - (DWORD)(cave + 13 + 5);
                *(DWORD*)(cave + 14) = jmpBackRel;

                /* Patch 'jmp epilogue' target: jump to 0x005AE39D */
                DWORD epilogueAddr = 0x005AE39D;
                DWORD epilogueRel = epilogueAddr - (DWORD)(cave + 18 + 5);
                *(DWORD*)(cave + 19) = epilogueRel;

                /* Now patch the original code at 0x005AE372 */
                BYTE *patchSite = (BYTE*)0x005AE372;
                DWORD oldProt;
                if (VirtualProtect(patchSite, 9, PAGE_EXECUTE_READWRITE, &oldProt)) {
                    /* E9 rel32 = JMP to cave */
                    patchSite[0] = 0xE9;
                    *(DWORD*)(patchSite + 1) = (DWORD)cave - (DWORD)(patchSite + 5);
                    /* NOP remaining 4 bytes */
                    patchSite[5] = 0x90;
                    patchSite[6] = 0x90;
                    patchSite[7] = 0x90;
                    patchSite[8] = 0x90;
                    VirtualProtect(patchSite, 9, oldProt, &oldProt);
                    Log("Crash fix installed at 0x005AE372 (script cmd NULL check)");
                } else {
                    Log("WARNING: Failed to patch 0x005AE372 (VirtualProtect failed)");
                }
            } else {
                Log("WARNING: Failed to allocate code cave for crash fix");
            }
        }
#endif /* DLC_ENABLE_CRASH_PATCH */

        BOOL printHooked = FALSE;
        BOOL debugPrintfPatched = FALSE;
        BOOL basePrintPatched = FALSE;

#if DLC_ENABLE_DEBUG_PRINTF_PATCH
        if (g_exeVerified) {
            ProbeSysWriteToConsole();

            if (VerifyRegPointsAtStub(VA_DEBUG_PRINTF_FUNC_PTR)) {
                DWORD old_func = 0;
                if (PatchLuaRegFuncPtr(VA_DEBUG_PRINTF_FUNC_PTR,
                                       Hook_LogPrintf, &old_func)) {
                    debugPrintfPatched = TRUE;
                    Log("Debug.Printf patched (reg 0x%08X: 0x%08X → Hook_LogPrintf)",
                        VA_DEBUG_PRINTF_FUNC_PTR, old_func);
                }
            } else {
                Log("WARNING: Debug.Printf reg 0x%08X does not point at stub — skip patch",
                    VA_DEBUG_PRINTF_FUNC_PTR);
            }

            if (VerifyRegPointsAtStub(VA_BASE_PRINT_FUNC_PTR)) {
                DWORD old_func = 0;
                if (PatchLuaRegFuncPtr(VA_BASE_PRINT_FUNC_PTR,
                                       Hook_LogPrintf, &old_func)) {
                    basePrintPatched = TRUE;
                    Log("print() patched (reg 0x%08X: 0x%08X → Hook_LogPrintf)",
                        VA_BASE_PRINT_FUNC_PTR, old_func);
                }
            } else {
                Log("WARNING: print() reg 0x%08X does not point at stub — skip patch",
                    VA_BASE_PRINT_FUNC_PTR);
            }
        }
#endif

#if DLC_ENABLE_PRINT_HOOK
        /* Legacy: hooks ALL callers of shared stub (traffic, spawners, etc.) */
        if (g_exeVerified && IsAddressExecutable(VA_PRINT_STUB)) {
            printHooked = InstallInlineHook(VA_PRINT_STUB,
                                            (void*)Hook_LogPrintf, &g_hookPrint);
            if (printHooked) {
                Log("WARNING: shared stub hook at 0x%08X (very noisy)", VA_PRINT_STUB);
            }
        }
#endif

        Log("Hooks: Online=%s Unlock=%s Matchmaking=%s Debug.Printf=%s print()=%s stub_hook=%s",
            g_origIsOnlineConnected ? "OK" : "FAIL",
            g_origHasPlayerUnlockedCode ? "OK" : "FAIL",
            matchHooked ? "OK" : "FAIL",
            debugPrintfPatched ? "PATCH" : "off",
            basePrintPatched ? "PATCH" : "off",
            printHooked ? "ON" : "off");

#ifdef DLC_ENABLE_MSGBOX
        MessageBoxA(NULL,
                    "dlc_enable.asi loaded successfully!\n\n"
                    "Check the debug console or pmc_blackbox.log for details.",
                    "DLC Enable Plugin", MB_OK | MB_ICONINFORMATION);
#endif

#if DLC_ENABLE_DEFERRED_BOOTSTRAP || DLC_ENABLE_BOOTSTRAP
        CreateThread(NULL, 0, InitThread, NULL, 0, NULL);
#endif
    }
    return TRUE;
}
