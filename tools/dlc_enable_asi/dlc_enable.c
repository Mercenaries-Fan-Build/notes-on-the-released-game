/**
 * dlc_enable.asi — DLC Content Activator for Mercenaries 2: World in Flames
 *
 * Bisection toggles (rebuild after changing; override on gcc command line):
 *
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
 *
 * Default build: Debug.Printf reg patch + net hooks. Minimal mode forces all non-net off:
 *   make dlc-asi-native EXTRA_CFLAGS="-DDLC_ENABLE_MINIMAL_MODE=1"
 *
 * Build: make dlc-asi-native  (or mingw in tools/dlc_enable_asi/)
 *
 * IMPORTANT: cracked EXE only (53,482,288 bytes). All VAs are binary-specific.
 */

#ifndef DLC_ENABLE_MINIMAL_MODE
#define DLC_ENABLE_MINIMAL_MODE       0
#endif

#if DLC_ENABLE_MINIMAL_MODE
#define DLC_ENABLE_VZ_LOAD_BOOTSTRAP    0
#define DLC_ENABLE_BOOTSTRAP          0
#define DLC_ENABLE_DEFERRED_BOOTSTRAP 0
#define DLC_ENABLE_CRASH_PATCH        0
#define DLC_ENABLE_PRINT_HOOK           0
#define DLC_ENABLE_DEBUG_PRINTF_PATCH   0
#define DLC_ENABLE_NET_HOOKS              1
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
#endif /* DLC_ENABLE_MINIMAL_MODE */

#define LUA_LOG_FLUSH_INTERVAL_LINES  64
#define LUA_LOG_FLUSH_INTERVAL_MS     500

/* Deferred bootstrap: require loadMainShell seen AND this minimum wait. */
#define DEFERRED_BOOTSTRAP_MIN_MS  (120 * 1000)
#define DEFERRED_BOOTSTRAP_MAX_MS  (180 * 1000)
/* VZ-load: inject outside print hook after masterscript line (avoids re-entrancy). */
#define VZ_LOAD_BOOTSTRAP_DELAY_MS  3000
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
static volatile LONG g_shellReady = 0;
static volatile LONG g_inPrintHook = 0;
static volatile LONG g_vzBootstrapThreadActive = 0;
static BOOL g_exeVerified = FALSE;

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

static void TryDLCBootstrap(lua_State* L);
static void LogLuaStackTopError(lua_State* L);
#if DLC_ENABLE_VZ_LOAD_BOOTSTRAP
static DWORD WINAPI VzBootstrapThread(LPVOID param);
#endif

/* Debug.Printf / print() replacement — only logs string-first calls (no invalid-stack spam). */
static int Hook_LogPrintf(lua_State* L) {
    if (InterlockedCompareExchange(&g_inPrintHook, 1, 0) != 0) {
        return 0;
    }

    if (!L) {
        InterlockedExchange(&g_inPrintHook, 0);
        return 0;
    }

    LuaTValue* top  = NULL;
    LuaTValue* base = NULL;
    int nargs = 0;

    if (!ResolvePrintStack(L, &top, &base, &nargs)) {
        InterlockedExchange(&g_inPrintHook, 0);
        return 0;
    }

    if (nargs < 1) {
        InterlockedExchange(&g_inPrintHook, 0);
        return 0;
    }

    LuaTValue first;
    if (!PtrReadable(base, sizeof(LuaTValue))) {
        InterlockedExchange(&g_inPrintHook, 0);
        return 0;
    }
    first = *base;
    if (first.tt != LUA_TSTRING) {
        InterlockedExchange(&g_inPrintHook, 0);
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

#if DLC_ENABLE_VZ_LOAD_BOOTSTRAP
    if (!g_dlcBootstrapDone && strstr(buf, "Loading vz level with vz masterscript")) {
        if (g_capturedState == NULL) {
            InterlockedCompareExchangePointer((volatile PVOID*)&g_capturedState, L, NULL);
        }
        if (InterlockedCompareExchange(&g_vzBootstrapThreadActive, 1, 0) == 0) {
            Log("VZ-load bootstrap: scheduling deferred inject (L=0x%08X, delay %u ms)",
                (DWORD)L, (unsigned)VZ_LOAD_BOOTSTRAP_DELAY_MS);
            CreateThread(NULL, 0, VzBootstrapThread, NULL, 0, NULL);
        }
    }
#endif

    /* Release before I/O — FlushFileBuffers on every line was freezing layer load. */
    InterlockedExchange(&g_inPrintHook, 0);

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
            TryDLCBootstrap(L);
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

/* Run in _G; probe MrxUtil then dlc01 (print -> our hook). */
static const char* DLC_BOOTSTRAP_LUA =
    "if setfenv and getfenv then\n"
    "  local e = getfenv(0)\n"
    "  if e ~= _G then setfenv(0, _G) end\n"
    "end\n"
    "if not import then error('import unavailable') end\n"
    "print('[dlc_enable] probe MrxUtil=' .. tostring(import('MrxUtil')))\n"
    "local m = import('dlc01')\n"
    "print('[dlc_enable] probe dlc01=' .. tostring(m) .. ' global=' .. tostring(dlc01))\n"
    "if m == nil then m = dlc01 end\n"
    "if m == nil and _MODULES then m = _MODULES.dlc01 or _MODULES['dlc01'] end\n"
    "if m == nil then\n"
    "  error('dlc01 not loaded — re-copy vz-patch.wad (run fix_dlc01_aset_type.py; ASET type_id must be 35)')\n"
    "end\n"
    "if m.ScriptInit == nil then error('dlc01.ScriptInit missing') end\n"
    "m.ScriptInit()\n";

/* SEH-like crash guard using vectored exception handling (MinGW-compatible) */
static volatile LONG g_inInjection = 0;
static LONG CALLBACK InjectionCrashGuard(PEXCEPTION_POINTERS info) {
    if (g_inInjection) {
        Log("DLC bootstrap: CRASH caught (exception 0x%08X at 0x%08X)",
            info->ExceptionRecord->ExceptionCode,
            (DWORD)info->ExceptionRecord->ExceptionAddress);
        if (info->ExceptionRecord->ExceptionAddress == (PVOID)0x005AE372) {
            Log("DLC bootstrap: hit 0x005AE372 — rebuild with CRASH_PATCH=1 (default dlc-asi-native)");
        }
        g_inInjection = 0;
        InterlockedExchange(&g_dlcBootstrapDone, 0);
        return EXCEPTION_EXECUTE_HANDLER;
    }
    return EXCEPTION_CONTINUE_SEARCH;
}

static void TryDLCBootstrap(lua_State* L) {
    if (InterlockedCompareExchange(&g_dlcBootstrapDone, 1, 0) != 0) {
        return;
    }

    if (!L) {
        InterlockedExchange(&g_dlcBootstrapDone, 0);
        return;
    }

    if (!g_exeVerified) {
        Log("DLC bootstrap: skipped (EXE mismatch)");
        return;
    }

    if (!IsAddressExecutable(VA_LUAL_LOADBUFFER) ||
        !IsAddressExecutable(VA_LUA_PCALL)) {
        Log("DLC bootstrap: skipped (target addresses not executable)");
        return;
    }

    Log("DLC bootstrap: injecting via luaL_loadbuffer(0x%08X) + lua_pcall(0x%08X)",
        VA_LUAL_LOADBUFFER, VA_LUA_PCALL);

    size_t code_len = strlen(DLC_BOOTSTRAP_LUA);

    PVOID veh = AddVectoredExceptionHandler(1, InjectionCrashGuard);
    g_inInjection = 1;

    Log("DLC bootstrap: fn=0x%08X L=0x%08X code=0x%08X len=%d name=0x%08X",
        VA_LUAL_LOADBUFFER, (DWORD)L, (DWORD)DLC_BOOTSTRAP_LUA, (int)code_len, (DWORD)"=dlc_enable");

    int load_result = call_luaL_loadbuffer(L, DLC_BOOTSTRAP_LUA, code_len, "=dlc_enable");

    Log("DLC bootstrap: luaL_loadbuffer returned %d", load_result);

    if (load_result != LUA_OK) {
        g_inInjection = 0;
        if (veh) RemoveVectoredExceptionHandler(veh);
        Log("DLC bootstrap: loadbuffer failed (code %d)", load_result);
        return;
    }

    Log("DLC bootstrap: calling lua_pcall...");

    int pcall_result = call_lua_pcall_simple(L);

    Log("DLC bootstrap: lua_pcall returned %d", pcall_result);

    g_inInjection = 0;
    if (veh) RemoveVectoredExceptionHandler(veh);

    if (pcall_result != LUA_OK) {
        Log("DLC bootstrap: pcall failed (code %d = %s)",
            pcall_result,
            pcall_result == 2 ? "LUA_ERRRUN" :
            pcall_result == 3 ? "LUA_ERRMEM" :
            pcall_result == 4 ? "LUA_ERRERR" : "other");
        LogLuaStackTopError(L);
        InterlockedExchange(&g_dlcBootstrapDone, 0);
        return;
    }

    Log("DLC bootstrap: injection successful");
}

#if DLC_ENABLE_VZ_LOAD_BOOTSTRAP
static DWORD WINAPI VzBootstrapThread(LPVOID param) {
    (void)param;
    Sleep(VZ_LOAD_BOOTSTRAP_DELAY_MS);
    for (int i = 0; i < 400 && g_inPrintHook; i++) {
        Sleep(25);
    }
    if (!g_capturedState) {
        Log("VZ-load bootstrap: aborted (no lua_State*)");
        InterlockedExchange(&g_vzBootstrapThreadActive, 0);
        return 0;
    }
    Log("VZ-load bootstrap: running deferred inject (L=0x%08X)", (DWORD)g_capturedState);
    TryDLCBootstrap((lua_State*)g_capturedState);
    InterlockedExchange(&g_vzBootstrapThreadActive, 0);
    return 0;
}
#endif

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
            TryDLCBootstrap((lua_State*)g_capturedState);
        }
    }
#elif DLC_ENABLE_BOOTSTRAP
    if (g_capturedState && !g_dlcBootstrapDone) {
        TryDLCBootstrap((lua_State*)g_capturedState);
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
        Log("Build: VZ_LOAD bootstrap=%s (expect ~19456 bytes; 17920 = old copy)",
            DLC_ENABLE_VZ_LOAD_BOOTSTRAP ? "ON" : "OFF");
        Log("Flags: MINIMAL=%d VZ_LOAD=%d BOOTSTRAP=%d DEFERRED=%d CRASH_PATCH=%d STUB_HOOK=%d REG_PATCH=%d LUA_VERBOSE=%d NET=%d",
            DLC_ENABLE_MINIMAL_MODE, DLC_ENABLE_VZ_LOAD_BOOTSTRAP, DLC_ENABLE_BOOTSTRAP,
            DLC_ENABLE_DEFERRED_BOOTSTRAP,
            DLC_ENABLE_CRASH_PATCH, DLC_ENABLE_PRINT_HOOK, DLC_ENABLE_DEBUG_PRINTF_PATCH,
            DLC_ENABLE_LUA_LOG_VERBOSE, DLC_ENABLE_NET_HOOKS);
        if (!DLC_ENABLE_VZ_LOAD_BOOTSTRAP && !DLC_ENABLE_BOOTSTRAP && !DLC_ENABLE_DEFERRED_BOOTSTRAP) {
            Log("WARNING: bootstrap OFF — rebuild with: make dlc-asi-native");
        }

        /* Verify EXE matches expected binary */
        g_exeVerified = VerifyExeSize();
        if (!g_exeVerified) {
            Log("WARNING: EXE size mismatch — hardcoded VAs may be wrong, injection disabled");
        }

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
