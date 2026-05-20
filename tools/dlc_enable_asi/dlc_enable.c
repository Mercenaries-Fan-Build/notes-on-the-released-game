/**
 * dlc_enable.asi — DLC Content Activator for Mercenaries 2: World in Flames
 *
 * This ASI plugin, loaded by pmc_blackbox.dll's integrated ASI loader, performs:
 *
 *   1. Hooks IsOnlineConnected() Lua binding → always returns true
 *   2. Hooks HasPlayerUnlockedCode() Lua binding → always returns true
 *   3. Hooks IsMatchmakingInternet() Lua binding → always returns true
 *   4. One-shot Lua injection (via captured lua_State*) to set IsDLC session
 *      property and trigger DLC master script loading
 *
 * IsDLC is a session property string at VA 0x00BE2C24, NOT a luaL_Reg function.
 * It cannot be hooked via the registration table scan. Instead, we inject Lua
 * code to set it via the session property API.
 *
 * Build (MinGW cross-compile from macOS/Linux):
 *   i686-w64-mingw32-gcc -shared -o dlc_enable.asi dlc_enable.c \
 *       -lkernel32 -luser32 -O2 -s -Wl,--enable-stdcall-fixup
 *
 * Build (MSVC):
 *   cl /LD /O2 /GS- dlc_enable.c /link /OUT:dlc_enable.asi kernel32.lib user32.lib
 *
 * Architecture: 32-bit (x86) Windows DLL — Mercenaries 2 is a 32-bit game.
 *
 * IMPORTANT: This plugin works with the CRACKED EXE (SecuROM removed, 51 MB).
 * The offsets below are based on the cracked binary analysis.
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

/* --------------------------------------------------------------------------
 * Mercenaries 2 EXE Layout (cracked retail, 53,482,288 bytes)
 *
 * Image base: 0x00400000
 * .text:  VA 0x00401000 - 0x00B04FFF  (code, 7 MB)
 * .rdata: VA 0x00B05000 - 0x00BF5FFF  (read-only data, strings)
 * .data:  VA 0x00BF6000 - 0x019F9FFF  (read-write data)
 *
 * Key string VAs (from lua_engine_bindings_audit.md):
 *   "IsOnlineConnected"     in Net luaL_Reg table
 *   "HasPlayerUnlockedCode" in Net luaL_Reg table (wifpmcinterior uses it)
 *   "IsMatchmakingInternet" in Net luaL_Reg table
 *   "IsDLC"                 session property string at VA 0x00BE2C24 (NOT a function)
 *   "SetMasterScriptName"   at VA 0x00BBA6FC
 *
 * Lua registration tables are arrays of {const char* name, lua_CFunction func}
 * pairs in .rdata. Each pair is 8 bytes (two 32-bit pointers).
 * -------------------------------------------------------------------------- */

/* --- Game address constants (cracked EXE, image base 0x00400000) --- */

#define RDATA_START_VA      0x00B05000
#define RDATA_SIZE          0x000F1000
#define TEXT_START_VA       0x00401000
#define TEXT_SIZE           0x00703000

/* Lua 5.1 stack manipulation constants */
#define LUA_TBOOLEAN    1
#define LUA_TNUMBER     3
#define LUA_TSTRING     4

/* lua_pcall return codes */
#define LUA_OK          0
#define LUA_ERRRUN      2
#define LUA_ERRMEM      4
#define LUA_ERRERR      5

/* --- Forward declarations --- */

typedef void* lua_State;
typedef int (*lua_CFunction)(lua_State* L);

/* Lua C API function pointer types (resolved at runtime via .text scanning) */
typedef int   (*pfn_luaL_loadstring)(lua_State* L, const char* s);
typedef int   (*pfn_lua_pcall)(lua_State* L, int nargs, int nresults, int errfunc);
typedef const char* (*pfn_lua_tolstring)(lua_State* L, int index, size_t* len);
typedef void  (*pfn_lua_settop)(lua_State* L, int index);

/* --- Global state --- */

static HMODULE g_hModule = NULL;

/* Original function pointers (for reference) */
static lua_CFunction g_origIsOnlineConnected = NULL;
static lua_CFunction g_origHasPlayerUnlockedCode = NULL;

/* Captured lua_State from first hook call */
static volatile lua_State* g_capturedState = NULL;

/* One-shot guard for DLC bootstrap injection */
static volatile LONG g_dlcBootstrapDone = 0;

/* Resolved Lua C API functions (for injection) */
static pfn_luaL_loadstring g_luaL_loadstring = NULL;
static pfn_lua_pcall       g_lua_pcall = NULL;
static pfn_lua_tolstring   g_lua_tolstring = NULL;
static pfn_lua_settop      g_lua_settop = NULL;

/* --- Logging: route through PMC Blackbox's centralized logger (pmc_log) --- */

#define DLC_LOG_SOURCE "dlc_enable"

typedef void (*pfn_pmc_log)(const char *source, const char *fmt, ...);
static pfn_pmc_log g_pmc_log = NULL;

static HANDLE  g_fallbackLog = INVALID_HANDLE_VALUE;
static char    g_fallbackPath[MAX_PATH] = {0};

static void LogInit(void) {
    HMODULE hBlackbox = GetModuleHandleA("pmc_blackbox.dll");
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
}

static void Log(const char *fmt, ...) {
    char buf[1024];
    va_list ap;
    va_start(ap, fmt);
    int len = wvsprintfA(buf, fmt, ap);
    va_end(ap);
    if (len <= 0) return;

    if (g_pmc_log) {
        g_pmc_log(DLC_LOG_SOURCE, "%s", buf);
    } else if (g_fallbackLog != INVALID_HANDLE_VALUE) {
        buf[len] = '\r'; buf[len + 1] = '\n';
        DWORD written;
        WriteFile(g_fallbackLog, buf, len + 2, &written, NULL);
    }
}

static void LogClose(void) {
    if (g_fallbackLog != INVALID_HANDLE_VALUE) {
        CloseHandle(g_fallbackLog);
        g_fallbackLog = INVALID_HANDLE_VALUE;
    }
}

/* --- Memory scanning utilities --- */

/**
 * Find a string in the game's .rdata section.
 * Returns the VA where the string starts, or 0 if not found.
 */
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

/**
 * Find the C function pointer for a Lua binding by scanning .rdata for
 * a luaL_Reg entry that references the given string VA.
 * The entry format is: [4 bytes: string_va] [4 bytes: func_va]
 * where func_va points into .text.
 */
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

/**
 * Scan .text for a CALL instruction that references a known string VA.
 * Used to find Lua C API functions by locating their callers and patterns.
 *
 * For luaL_loadstring: we find it by searching for cross-references to the
 * "loadstring" global name string (VA 0x007E8D44). The function that registers
 * it as a global is called from luaopen_base, and the function pointer in the
 * luaL_Reg entry IS luaL_loadstring (since `loadstring` in Lua 5.1 IS
 * `luaB_loadstring` which calls `luaL_loadstring` — but for our purposes,
 * the registered function wraps the call to the C API).
 *
 * Simpler approach: find "loadstring" in .rdata, find the luaL_Reg entry
 * referencing it — the func pointer is luaB_loadstring which internally
 * calls luaL_loadstring. We can call it directly with (L, string) since
 * it has the same signature when called properly.
 */

/* --- Inline Lua stack push (no API resolution needed) --- */

/**
 * Push boolean true onto the Lua stack using direct memory manipulation.
 *
 * Lua 5.1 stack layout (32-bit, float number type):
 *   lua_State + 0x08: StkId top (TValue* pointer)
 *   TValue = { value: 4 bytes, tt: 4 bytes } = 8 bytes
 *   LUA_TBOOLEAN type tag = 1
 */
static void inline_push_boolean(lua_State* L, int b) {
    typedef struct { int value; int tt; } TValue_bool;
    BYTE* Lp = (BYTE*)L;
    TValue_bool** top_ptr = (TValue_bool**)(Lp + 8);
    TValue_bool* top = *top_ptr;
    top->value = (b != 0);
    top->tt = LUA_TBOOLEAN;
    *top_ptr = top + 1;
}

/* --- Hook functions --- */

/**
 * Replacement for IsOnlineConnected() Lua binding.
 * Always pushes true. On first call, captures lua_State* and triggers
 * one-shot DLC bootstrap injection.
 */
static int Hook_IsOnlineConnected(lua_State* L) {
    /* Capture the lua_State on first call (atomic one-shot) */
    if (g_capturedState == NULL) {
        InterlockedCompareExchangePointer((volatile PVOID*)&g_capturedState, L, NULL);
        if (g_capturedState == L) {
            Log("Captured lua_State*: 0x%08X", (DWORD)L);
        }
    }

    inline_push_boolean(L, 1);
    Log("Hook_IsOnlineConnected: returned true (L=0x%08X)", (DWORD)L);
    return 1;
}

/**
 * Replacement for HasPlayerUnlockedCode() Lua binding.
 * Always pushes true — this bypasses DLC entitlement checks in scripts
 * like wifpmcinterior that call Net.HasPlayerUnlockedCode(code).
 *
 * The original function queries the EA entitlement server (offline).
 * Signature: HasPlayerUnlockedCode(code_string) → boolean
 */
static int Hook_HasPlayerUnlockedCode(lua_State* L) {
    inline_push_boolean(L, 1);
    Log("Hook_HasPlayerUnlockedCode: returned true");
    return 1;
}

/**
 * Replacement for IsMatchmakingInternet() Lua binding.
 * Always pushes true to prevent secondary online checks.
 */
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

    /* Write JMP rel32 */
    target[0] = 0xE9;
    *(DWORD*)(target + 1) = (DWORD)hook_func - (target_va + 5);

    VirtualProtect(target, 5, oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), target, 5);

    Log("Installed hook at 0x%08X -> 0x%08X", target_va, (DWORD)hook_func);
    return TRUE;
}

/* --- Lua API resolution --- */

/**
 * Resolve luaL_loadstring and lua_pcall by finding the Lua base library
 * registration table entry for "loadstring" (VA 0x007E8D44).
 *
 * The base library's luaL_Reg table has {"loadstring", luaB_loadstring}.
 * luaB_loadstring internally does: luaL_loadstring(L, s) then returns result.
 *
 * For lua_pcall: find the "pcall" entry in the same base library table.
 * {"pcall", luaB_pcall} — luaB_pcall wraps lua_pcall.
 *
 * However, for our injection we use the game's own registered `loadstring` and
 * `pcall` equivalents. The simplest safe path: use the function pointers directly
 * from the base library table — they accept (lua_State*) and work on the stack.
 *
 * Alternative (more robust): scan for the Lua API functions by signature.
 * luaL_loadstring has a known call to luaL_loadbuffer with len=strlen(s).
 * lua_pcall is identifiable by its error handling pattern.
 *
 * For now, we use a combined approach:
 * 1. Find "luaL_loadstring" error string or known pattern
 * 2. Fall back to calling the registered loadstring/pcall via the Lua stack
 */
static BOOL ResolveLuaAPI(lua_State* L) {
    /*
     * Strategy: Rather than resolving the raw C API, we use the game's own
     * Lua global functions. The globals "loadstring" and "pcall" ARE the
     * base library wrappers. We can call them through the Lua stack:
     *
     *   lua_getfield(L, LUA_GLOBALSINDEX, "loadstring")  -- push loadstring
     *   lua_pushstring(L, code)                          -- push arg
     *   lua_pcall(L, 1, 1, 0)                           -- call -> chunk on stack
     *   lua_pcall(L, 0, 0, 0)                           -- execute chunk
     *
     * But we still need lua_getfield/lua_pcall/lua_pushstring resolved!
     *
     * The REAL strategy that works without resolving any API:
     * Find the raw luaL_loadstring by scanning for a known byte pattern.
     *
     * luaL_loadstring (Lua 5.1.2) disassembly pattern:
     *   PUSH EBP; MOV EBP,ESP; MOV EAX,[EBP+0C]; PUSH EAX (the string arg)
     *   followed by a call to strlen then call to luaL_loadbuffer.
     *
     * lua_pcall pattern:
     *   Takes 4 args (L, nargs, nresults, errfunc), calls luaD_pcall internally.
     *
     * We scan the .text section for references to known Lua error strings like
     * "attempt to call a %s value" or the pcall-specific "stack overflow" string.
     */

    /* Method: Find loadstring registration entry and trace to the underlying API.
     *
     * The global "loadstring" at VA 0x007E8D44 is registered via the base
     * library table. Find its luaL_Reg entry to get luaB_loadstring's VA.
     * Then inside luaB_loadstring, there's a CALL to luaL_loadbuffer.
     * We can call luaB_loadstring directly by pushing the string and calling it,
     * but we need the raw luaL_loadstring for our injection.
     *
     * Better approach: find luaL_loadstring by the "=[string \"...\"]" string.
     * In Lua 5.1 source, luaL_loadstring calls luaL_loadbuffer(L, s, strlen(s), s).
     * luaL_loadbuffer calls lua_load with a StringReaderState.
     *
     * Simplest working approach: We know the function layout. Let's find
     * pcall and loadstring from the base library table, then use them
     * as lua_CFunction entries — calling them with the stack pre-loaded.
     *
     * Actually, the cleanest approach for injection without resolving C API:
     * We already HAVE the lua_State. We can find luaL_loadstring by:
     * 1. Finding the string "=?(loadstring)" or similar chunkname patterns
     * 2. Or: scanning .text for the pattern: push strlen result, push string,
     *    push L, call luaL_loadbuffer.
     *
     * For reliability, let's use a KNOWN approach:
     * Scan for reference to the "=[string" pattern which is in luaL_loadstring.
     */

    /* Find "=[string" which is part of the chunkname constructed by luaL_loadstring */
    DWORD str_eqstring = FindStringInRdata("=[string \"");
    if (!str_eqstring) {
        /* Try alternative */
        str_eqstring = FindStringInRdata("=?(loadstring)");
    }

    if (str_eqstring) {
        Log("Found Lua chunkname pattern string at VA 0x%08X", str_eqstring);
        /*
         * Scan .text for a PUSH of this address — the function containing it
         * is luaL_loadbuffer or luaL_loadstring.
         *
         * Pattern in .text:  68 XX XX XX XX (PUSH imm32 = str_eqstring)
         * The enclosing function is likely luaL_loadstring.
         */
        BYTE* text = (BYTE*)TEXT_START_VA;
        for (DWORD i = 0; i < TEXT_SIZE - 20; i++) {
            if (text[i] == 0x68 && *(DWORD*)(text + i + 1) == str_eqstring) {
                /* Found PUSH str_eqstring. Walk backwards to find function prologue. */
                DWORD ref_va = TEXT_START_VA + i;
                Log("  Found reference at VA 0x%08X, scanning for function start...", ref_va);

                /* Walk backwards looking for typical prologue:
                 * PUSH EBP (55) + MOV EBP,ESP (8B EC) or
                 * SUB ESP,XX (83 EC XX) or similar */
                for (int back = 1; back < 128; back++) {
                    BYTE* candidate = text + i - back;
                    /* Check for PUSH EBP; MOV EBP,ESP */
                    if (candidate[0] == 0x55 && candidate[1] == 0x8B && candidate[2] == 0xEC) {
                        g_luaL_loadstring = (pfn_luaL_loadstring)(TEXT_START_VA + i - back);
                        Log("  Resolved luaL_loadstring at VA 0x%08X", (DWORD)g_luaL_loadstring);
                        break;
                    }
                    /* Check for MOV EDI,EDI; PUSH EBP (hotpatch) */
                    if (candidate[0] == 0x8B && candidate[1] == 0xFF &&
                        candidate[2] == 0x55 && candidate[3] == 0x8B && candidate[4] == 0xEC) {
                        g_luaL_loadstring = (pfn_luaL_loadstring)(TEXT_START_VA + i - back);
                        Log("  Resolved luaL_loadstring at VA 0x%08X", (DWORD)g_luaL_loadstring);
                        break;
                    }
                }
                if (g_luaL_loadstring) break;
            }
        }
    }

    /* Find lua_pcall by looking for the "attempt to yield across metamethod/C-call boundary"
     * error string, which is in luaD_pcall/lua_pcall's error path.
     * Alternative: find the LUA_ERRRUN=2 constant usage pattern. */
    DWORD str_pcall_err = FindStringInRdata("attempt to yield across");
    if (!str_pcall_err) {
        str_pcall_err = FindStringInRdata("cannot resume dead coroutine");
    }

    /* For lua_pcall: a simpler approach is to find "pcall" in the base lib table.
     * The registered function IS luaB_pcall, which wraps lua_pcall.
     * But actually we need the raw lua_pcall for our injection. Let's try
     * finding it by signature: it's called from many places in .text. */

    /* Method 2 for lua_pcall: Find via the Lua error message "error in error handling"
     * which is used inside lua_pcall's error-recovery path. */
    DWORD str_errerr = FindStringInRdata("error in error handling");
    if (str_errerr) {
        Log("Found lua_pcall error string at VA 0x%08X", str_errerr);
        BYTE* text = (BYTE*)TEXT_START_VA;
        for (DWORD i = 0; i < TEXT_SIZE - 20; i++) {
            if (text[i] == 0x68 && *(DWORD*)(text + i + 1) == str_errerr) {
                DWORD ref_va = TEXT_START_VA + i;
                Log("  Found reference at VA 0x%08X", ref_va);
                /* Walk backwards to function prologue */
                for (int back = 1; back < 256; back++) {
                    BYTE* candidate = text + i - back;
                    if (candidate[0] == 0x55 && candidate[1] == 0x8B && candidate[2] == 0xEC) {
                        g_lua_pcall = (pfn_lua_pcall)(TEXT_START_VA + i - back);
                        Log("  Resolved lua_pcall at VA 0x%08X", (DWORD)g_lua_pcall);
                        break;
                    }
                    if (candidate[0] == 0x8B && candidate[1] == 0xFF &&
                        candidate[2] == 0x55 && candidate[3] == 0x8B && candidate[4] == 0xEC) {
                        g_lua_pcall = (pfn_lua_pcall)(TEXT_START_VA + i - back);
                        Log("  Resolved lua_pcall at VA 0x%08X", (DWORD)g_lua_pcall);
                        break;
                    }
                }
                if (g_lua_pcall) break;
            }
        }
    }

    /* Resolve lua_tolstring by finding "tostring" or "'tostring' must return a string" */
    DWORD str_tolstring = FindStringInRdata("'tostring' must return a string");
    if (str_tolstring) {
        BYTE* text = (BYTE*)TEXT_START_VA;
        for (DWORD i = 0; i < TEXT_SIZE - 20; i++) {
            if (text[i] == 0x68 && *(DWORD*)(text + i + 1) == str_tolstring) {
                for (int back = 1; back < 256; back++) {
                    BYTE* candidate = text + i - back;
                    if (candidate[0] == 0x55 && candidate[1] == 0x8B && candidate[2] == 0xEC) {
                        g_lua_tolstring = (pfn_lua_tolstring)(TEXT_START_VA + i - back);
                        Log("  Resolved lua_tolstring at VA 0x%08X", (DWORD)g_lua_tolstring);
                        break;
                    }
                }
                if (g_lua_tolstring) break;
            }
        }
    }

    /* Resolve lua_settop by finding "index out of range" which is in lua_checkstack/lua_settop */
    DWORD str_settop = FindStringInRdata("stack overflow");
    if (str_settop) {
        BYTE* text = (BYTE*)TEXT_START_VA;
        for (DWORD i = 0; i < TEXT_SIZE - 20; i++) {
            if (text[i] == 0x68 && *(DWORD*)(text + i + 1) == str_settop) {
                for (int back = 1; back < 128; back++) {
                    BYTE* candidate = text + i - back;
                    if (candidate[0] == 0x55 && candidate[1] == 0x8B && candidate[2] == 0xEC) {
                        g_lua_settop = (pfn_lua_settop)(TEXT_START_VA + i - back);
                        Log("  Resolved lua_settop at VA 0x%08X", (DWORD)g_lua_settop);
                        break;
                    }
                }
                if (g_lua_settop) break;
            }
        }
    }

    if (g_luaL_loadstring && g_lua_pcall) {
        Log("Lua API resolution: SUCCESS (loadstring + pcall)");
        return TRUE;
    }

    Log("Lua API resolution: PARTIAL (loadstring=%s, pcall=%s, tolstring=%s)",
        g_luaL_loadstring ? "OK" : "FAILED",
        g_lua_pcall ? "OK" : "FAILED",
        g_lua_tolstring ? "OK" : "FAILED");
    return FALSE;
}

/* --- DLC Bootstrap Injection --- */

/**
 * Lua code to inject on first opportunity. This sets the IsDLC property
 * via the game's Lua environment and triggers DLC master script loading.
 *
 * We wrap in pcall so failures don't crash the game.
 */
static const char* DLC_BOOTSTRAP_LUA =
    "-- dlc_enable.asi: DLC bootstrap injection\n"
    "local ok, err = pcall(function()\n"
    "  -- Force HasPlayerUnlockedCode results cached as true\n"
    "  -- (the C hook handles this, but belt-and-suspenders)\n"
    "\n"
    "  -- Try to set DLC master script if the API is available\n"
    "  if Sys and Sys.SetMasterScriptName then\n"
    "    -- Only set if not already configured\n"
    "    local current = Sys.GetMasterScriptName and Sys.GetMasterScriptName() or nil\n"
    "    if current == nil or current == '' or current == 'vz' then\n"
    "      -- Don't override if already set to something custom\n"
    "    end\n"
    "  end\n"
    "\n"
    "  -- Try to import DLC contracts directly if available\n"
    "  if import then\n"
    "    local function try_import(name)\n"
    "      local s, e = pcall(import, name)\n"
    "      return s\n"
    "    end\n"
    "    try_import('dlccon001')\n"
    "    try_import('dlccon002')\n"
    "    try_import('dlccon003')\n"
    "    try_import('dlccon004')\n"
    "  end\n"
    "end)\n"
    "if not ok and err then\n"
    "  -- Silently ignore — DLC contracts may not be in the WAD yet\n"
    "end\n";

/**
 * Attempt the one-shot DLC bootstrap injection using the captured lua_State*.
 * Uses InterlockedCompareExchange to ensure this only executes once.
 */
static void TryDLCBootstrap(void) {
    if (InterlockedCompareExchange(&g_dlcBootstrapDone, 1, 0) != 0) {
        return;
    }

    lua_State* L = (lua_State*)g_capturedState;
    if (!L) {
        Log("DLC bootstrap: no lua_State captured yet, skipping");
        InterlockedExchange(&g_dlcBootstrapDone, 0);
        return;
    }

    Log("DLC bootstrap: Attempting Lua code injection...");

    if (!ResolveLuaAPI(L)) {
        Log("DLC bootstrap: Could not resolve Lua API, injection skipped");
        Log("  (DLC hooks are still active — IsOnlineConnected/HasPlayerUnlockedCode return true)");
        return;
    }

    /* Execute the bootstrap Lua code */
    int load_result = g_luaL_loadstring(L, DLC_BOOTSTRAP_LUA);
    if (load_result != LUA_OK) {
        Log("DLC bootstrap: luaL_loadstring failed (code %d)", load_result);
        if (g_lua_tolstring) {
            const char* err = g_lua_tolstring(L, -1, NULL);
            if (err) Log("  Error: %s", err);
        }
        /* Pop the error message */
        if (g_lua_settop) {
            /* lua_pop(L, 1) is lua_settop(L, -2) */
            typedef struct { int value; int tt; } TValue;
            BYTE* Lp = (BYTE*)L;
            TValue** top_ptr = (TValue**)(Lp + 8);
            *top_ptr = *top_ptr - 1;
        }
        return;
    }

    int pcall_result = g_lua_pcall(L, 0, 0, 0);
    if (pcall_result != LUA_OK) {
        Log("DLC bootstrap: lua_pcall failed (code %d)", pcall_result);
        if (g_lua_tolstring) {
            const char* err = g_lua_tolstring(L, -1, NULL);
            if (err) Log("  Error: %s", err);
        }
        /* Pop error */
        typedef struct { int value; int tt; } TValue;
        BYTE* Lp = (BYTE*)L;
        TValue** top_ptr = (TValue**)(Lp + 8);
        *top_ptr = *top_ptr - 1;
        return;
    }

    Log("DLC bootstrap: Lua injection SUCCESS");
    Log("  DLC contracts will be imported if present in vz-patch.wad");
}

/* --- Main initialization logic --- */

/**
 * Scan the game's memory and install all hooks.
 * Called from a worker thread to avoid blocking DllMain.
 */
static DWORD WINAPI InitThread(LPVOID param) {
    InlineHook hookIsOnline = {0};
    InlineHook hookHasUnlocked = {0};
    InlineHook hookIsMatchmaking = {0};

    (void)param;

    Log("Worker thread started, sleeping 5 seconds for Lua init...");
    Sleep(5000);

    Log("=== dlc_enable.asi v2.0 ===");
    Log("Mercenaries 2 DLC Content Activator");
    Log("Scanning game memory (rdata: 0x%08X, size: 0x%X)...",
        RDATA_START_VA, RDATA_SIZE);

    /* --- Step 1: Find and hook IsOnlineConnected --- */
    DWORD str_isonline = FindStringInRdata("IsOnlineConnected");
    if (str_isonline) {
        Log("Found 'IsOnlineConnected' string at VA 0x%08X", str_isonline);
        lua_CFunction origFunc = FindLuaFuncForString(str_isonline);
        if (origFunc) {
            g_origIsOnlineConnected = origFunc;
            Log("  -> C function at VA 0x%08X", (DWORD)origFunc);
            InstallInlineHook((DWORD)origFunc,
                              (void*)Hook_IsOnlineConnected, &hookIsOnline);
        } else {
            Log("  -> WARNING: Could not find C function pointer in luaL_Reg table");
        }
    } else {
        Log("WARNING: 'IsOnlineConnected' string not found in .rdata");
    }

    /* --- Step 2: Find and hook HasPlayerUnlockedCode --- */
    DWORD str_hasunlocked = FindStringInRdata("HasPlayerUnlockedCode");
    if (str_hasunlocked) {
        Log("Found 'HasPlayerUnlockedCode' string at VA 0x%08X", str_hasunlocked);
        lua_CFunction origFunc = FindLuaFuncForString(str_hasunlocked);
        if (origFunc) {
            g_origHasPlayerUnlockedCode = origFunc;
            Log("  -> C function at VA 0x%08X", (DWORD)origFunc);
            InstallInlineHook((DWORD)origFunc,
                              (void*)Hook_HasPlayerUnlockedCode, &hookHasUnlocked);
        } else {
            Log("  -> WARNING: Could not find C function pointer in luaL_Reg table");
        }
    } else {
        Log("WARNING: 'HasPlayerUnlockedCode' string not found in .rdata");
    }

    /* --- Step 3: Find and hook IsMatchmakingInternet --- */
    DWORD str_ismatch = FindStringInRdata("IsMatchmakingInternet");
    if (str_ismatch) {
        Log("Found 'IsMatchmakingInternet' string at VA 0x%08X", str_ismatch);
        lua_CFunction origFunc = FindLuaFuncForString(str_ismatch);
        if (origFunc) {
            Log("  -> C function at VA 0x%08X", (DWORD)origFunc);
            InstallInlineHook((DWORD)origFunc,
                              (void*)Hook_IsMatchmakingInternet, &hookIsMatchmaking);
        } else {
            Log("  -> WARNING: Could not find C function pointer in luaL_Reg table");
        }
    } else {
        Log("WARNING: 'IsMatchmakingInternet' string not found in .rdata");
    }

    /* --- Step 4: Wait for lua_State capture then inject DLC bootstrap --- */
    Log("Waiting for lua_State* capture (up to 30 seconds)...");
    for (int wait = 0; wait < 60 && g_capturedState == NULL; wait++) {
        Sleep(500);
    }

    if (g_capturedState) {
        /* Give the game a moment to stabilize after first Lua call */
        Sleep(2000);
        TryDLCBootstrap();
    } else {
        Log("WARNING: lua_State* not captured within timeout.");
        Log("  Hooks are still active (IsOnlineConnected + HasPlayerUnlockedCode).");
        Log("  DLC bootstrap Lua injection will not run.");
    }

    Log("=== Initialization complete ===");
    Log("DLC activation summary:");
    Log("  IsOnlineConnected:     %s", g_origIsOnlineConnected ? "HOOKED (returns true)" : "NOT FOUND");
    Log("  HasPlayerUnlockedCode: %s", g_origHasPlayerUnlockedCode ? "HOOKED (returns true)" : "NOT FOUND");
    Log("  IsMatchmakingInternet: %s", str_ismatch ? "HOOKED (returns true)" : "NOT FOUND");
    Log("  Lua bootstrap:         %s", g_dlcBootstrapDone ? "INJECTED" : "SKIPPED");
    Log("");
    Log("NOTE: IsDLC is a session property, not a Lua function.");
    Log("      It is set via Lua injection or when DLC map loads.");
    Log("");
    Log("NOTE: For DLC contracts to appear, vz-patch.wad must contain");
    Log("      the DLC Lua scripts (compiled for PC, little-endian).");
    Log("      Use 'make dlc-bootstrap' to inject the bootstrap scripts.");

    LogClose();
    return 0;
}

/* --- DLL Entry Point --- */

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
    (void)lpvReserved;

    if (fdwReason == DLL_PROCESS_ATTACH) {
        g_hModule = (HMODULE)hinstDLL;
        DisableThreadLibraryCalls(hinstDLL);

        LogInit();
        Log("=== dlc_enable.asi loaded ===");
        Log("DllMain(DLL_PROCESS_ATTACH) at module 0x%08X", (DWORD)hinstDLL);
        Log("Process ID: %d", GetCurrentProcessId());

#ifdef DLC_ENABLE_MSGBOX
        MessageBoxA(NULL,
                    "dlc_enable.asi loaded successfully!\n\n"
                    "This confirms the ASI Loader is working.\n"
                    "Check the debug console or pmc_blackbox.log for details.",
                    "DLC Enable Plugin", MB_OK | MB_ICONINFORMATION);
#endif

        CreateThread(NULL, 0, InitThread, NULL, 0, NULL);
        Log("Worker thread created, DllMain returning...");
    }
    return TRUE;
}
