/**
 * lua_log_hook.c — native capture of the game's stripped-out logging stream.
 *
 * Lua-stack readers + Hook_LogPrintf ported from tools/dlc_enable_asi (logging
 * only — no bootstrap/net/arena machinery; pmc_bb just observes and records).
 * The INSTALL mechanism differs and is the whole point: instead of patching the
 * .rdata print/Debug.Printf func-pointer slots (which tripped SecuROM anti-
 * tamper and crashed early init before our hook ever ran — confirmed live), we
 * MinHook the shared no-op stub's CODE at 0x006D5640. ~700 stripped log fns
 * funnel through that stub, so one .text detour captures them all, leaves the
 * registration tables untouched, and is tolerated by SecuROM (compat_hooks
 * proves .text MinHook is fine).
 *
 * Addresses are HARDCODED for the cracked retail EXE (53,482,288 bytes). The
 * Lua C API here is Lua 5.1.2 32-bit (float numbers). The stub is 33 C0 C3
 * (xor eax,eax; ret) + 13 bytes 0xCC padding, so MinHook's 5-byte jmp fits with
 * zero collateral.
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <string.h>

#include "lua_log_hook.h"
#include "MinHook.h"

/* pmc_log / pmc_log_flush are exported from pmc_blackbox.c (same DLL). */
extern void pmc_log(const char *source, const char *fmt, ...);
extern void pmc_log_flush(void);

/* --- Hook target ---
 *
 * 0x006D5640 is the SHARED no-op stub (33 C0 C3 = xor eax,eax; ret) that the
 * production build redirected ~all stripped debug/log functions to (print,
 * Debug.Printf, and ~700 other subsystem log fns all point here). We MinHook
 * the stub's CODE rather than the .rdata func-ptr slots: SecuROM tolerates
 * .text MinHook detours (compat_hooks proves it) but anti-tampers .rdata
 * writes (a slot patch crashed early init before our hook ever ran). Hooking
 * here captures EVERY funneled subsystem at one site, leaves the registration
 * tables pristine, and is "earlier in the stack" than the Lua binding.
 *
 * Layout verified live: 33 C0 C3 then 13x 0xCC padding (0x006D5643..4F), next
 * function at 0x006D5650 — so MinHook's 5-byte jmp lands entirely in stub+pad,
 * zero collateral. */
#define VA_PRINT_STUB  0x006D5640

/* --- Lua 5.1.2 (32-bit, float number) layout --- */
typedef void  lua_State;
typedef int  (*lua_CFunction)(lua_State *L);
typedef struct { DWORD value; DWORD tt; } LuaTValue;

#define LUA_STATE_OFF_TOP         0x08
#define LUA_STATE_OFF_BASE        0x0C
#define LUA_STATE_OFF_CI          0x14
#define LUA_STATE_OFF_STACK_LAST  0x1C
#define LUA_STATE_OFF_STACK       0x20
#define CALLINFO_OFF_BASE         0x00
#define CALLINFO_OFF_FUNC         0x04

#define LUA_TBOOLEAN  1
#define LUA_TNUMBER   3
#define LUA_TSTRING   4

#define HOOK_PRINT_MAX_ARGS         32
#define HOOK_PRINT_MAX_STACK_SLOTS  10000

static volatile LONG g_inPrintHook = 0;

/* --- Safe memory access (precache print() can pass bad pointers) --- */

/* Bytes safely readable starting at p, within its single committed region.
 * ONE VirtualQuery — callers validate a whole span/string from the result
 * instead of querying per byte (which on the load thread is a syscall storm). */
static SIZE_T ReadableSpan(const void *p) {
    MEMORY_BASIC_INFORMATION mbi;
    ULONG_PTR region_end;

    if (!p) return 0;
    if (VirtualQuery(p, &mbi, sizeof(mbi)) == 0) return 0;
    if (mbi.State != MEM_COMMIT) return 0;
    if (mbi.Protect & (PAGE_NOACCESS | PAGE_GUARD)) return 0;

    switch (mbi.Protect & 0xFF) {
        case PAGE_READONLY:
        case PAGE_READWRITE:
        case PAGE_WRITECOPY:
        case PAGE_EXECUTE_READ:
        case PAGE_EXECUTE_READWRITE:
        case PAGE_EXECUTE_WRITECOPY:
            break;
        default:
            return 0;
    }

    region_end = (ULONG_PTR)mbi.BaseAddress + mbi.RegionSize;
    if ((ULONG_PTR)p >= region_end) return 0;
    return (SIZE_T)(region_end - (ULONG_PTR)p);
}

static BOOL PtrReadable(const void *p, SIZE_T nbytes) {
    if (nbytes == 0) return FALSE;
    return ReadableSpan(p) >= nbytes;
}

/* Copy a Lua TString payload (data starts at TString + 16 in 32-bit Lua 5.1).
 * One region query for the whole payload, then a bounded in-region copy — no
 * per-byte syscalls. The copy can never read past the committed region. */
static int SafeCopyTString(DWORD tstring_val, char *out, int out_max) {
    const char *str;
    SIZE_T span;
    int limit, slen;

    if (!tstring_val || out_max <= 1) return 0;
    /* Header must be readable (payload ptr base lives at +16). */
    if (ReadableSpan((void *)tstring_val) < 20) {
        strncpy(out, "(bad string)", out_max - 1);
        out[out_max - 1] = '\0';
        return 0;
    }
    str  = (const char *)((BYTE *)tstring_val + 16);
    span = ReadableSpan(str);  /* single query covering the payload region */
    if (span == 0) {
        strncpy(out, "(bad string)", out_max - 1);
        out[out_max - 1] = '\0';
        return 0;
    }

    limit = out_max - 1;
    if ((SIZE_T)limit > span) limit = (int)span;  /* never read past the region */
    slen = 0;
    while (slen < limit && str[slen]) {           /* no per-byte VirtualQuery */
        out[slen] = str[slen];
        slen++;
    }
    out[slen] = '\0';
    return slen;
}

static BOOL StkInRange(LuaTValue *p, LuaTValue *stack, LuaTValue *stack_last) {
    return p && stack && stack_last && stack <= stack_last &&
           p >= stack && p <= stack_last;
}

/* Resolve top/base and verify they lie in [stack, stack_last] with sane nargs. */
static BOOL ResolvePrintStack(lua_State *L, LuaTValue **out_top,
                              LuaTValue **out_base, int *out_nargs) {
    BYTE *Lp = (BYTE *)L;
    LuaTValue *top, *base, *stack, *stack_last;
    int nargs;

    if (!PtrReadable(Lp + LUA_STATE_OFF_STACK, sizeof(LuaTValue *) * 3)) return FALSE;

    top        = *(LuaTValue **)(Lp + LUA_STATE_OFF_TOP);
    base       = *(LuaTValue **)(Lp + LUA_STATE_OFF_BASE);
    stack_last = *(LuaTValue **)(Lp + LUA_STATE_OFF_STACK_LAST);
    stack      = *(LuaTValue **)(Lp + LUA_STATE_OFF_STACK);

    if (!StkInRange(stack, stack, stack_last)) return FALSE;
    if (!StkInRange(top, stack, stack_last)) return FALSE;

    if (!StkInRange(base, stack, stack_last)) {
        /* L->base can be 0 during VM transitions; try ci->func+1 (C precall). */
        if (PtrReadable(Lp + LUA_STATE_OFF_CI, sizeof(void *))) {
            BYTE *ci = *(BYTE **)(Lp + LUA_STATE_OFF_CI);
            if (ci && PtrReadable(ci + CALLINFO_OFF_FUNC, sizeof(LuaTValue *))) {
                LuaTValue *func = *(LuaTValue **)(ci + CALLINFO_OFF_FUNC);
                if (StkInRange(func, stack, stack_last)) {
                    base = func + 1;
                } else if (PtrReadable(ci + CALLINFO_OFF_BASE, sizeof(LuaTValue *))) {
                    LuaTValue *ci_base = *(LuaTValue **)(ci + CALLINFO_OFF_BASE);
                    if (StkInRange(ci_base, stack, stack_last)) base = ci_base;
                }
            }
        }
    }

    if (!StkInRange(base, stack, stack_last)) return FALSE;
    if (top < base) return FALSE;
    if (((ULONG_PTR)base & 3) != 0 || ((ULONG_PTR)top & 3) != 0) return FALSE;
    if (((ULONG_PTR)base - (ULONG_PTR)stack) % sizeof(LuaTValue) != 0 ||
        ((ULONG_PTR)top  - (ULONG_PTR)stack) % sizeof(LuaTValue) != 0) return FALSE;

    nargs = (int)(top - base);
    if (nargs <= 0 || nargs > HOOK_PRINT_MAX_ARGS) return FALSE;
    if ((ULONG)nargs > HOOK_PRINT_MAX_STACK_SLOTS) return FALSE;
    if (!PtrReadable(base, (SIZE_T)nargs * sizeof(LuaTValue))) return FALSE;

    *out_top = top;
    *out_base = base;
    *out_nargs = nargs;
    return TRUE;
}

/* --- World-load milestone tagging ---
 *
 * The whole point of this hook is to SEE load progress, so we log every line.
 * In addition, a handful of high-signal substrings are echoed under the "world"
 * source so milestones (esp. "global start") are trivially greppable. These are
 * substrings verified to appear in the engine's Lua output (see dlc_enable.c),
 * plus "global start" which the user uses as the world-entities-loading marker.
 * Matching is case-insensitive and allocation-free. */
static BOOL ContainsCI(const char *hay, const char *needle) {
    size_t nl = strlen(needle);
    if (!hay || !nl) return FALSE;
    for (; *hay; hay++) {
        size_t i = 0;
        while (i < nl) {
            char a = hay[i], b = needle[i];
            if (a >= 'A' && a <= 'Z') a = (char)(a + 32);
            if (b >= 'A' && b <= 'Z') b = (char)(b + 32);
            if (a != b) break;
            i++;
        }
        if (i == nl) return TRUE;
        if (!hay[i]) break; /* ran off the end mid-match */
    }
    return FALSE;
}

static void MaybeTagMilestone(const char *msg) {
    static const char *const kMilestones[] = {
        "global start",
        "Loading vz level with vz masterscript",
        "Shell exited",
        "Setting flow data",
        "WAITFORSTREAMING",
        "Dynamically imported module",
        "masterscript",
    };
    int i;
    for (i = 0; i < (int)(sizeof(kMilestones) / sizeof(kMilestones[0])); i++) {
        if (ContainsCI(msg, kMilestones[i])) {
            pmc_log("world", ">>> %s", msg);
            return;
        }
    }
}

/* --- The bridge: game's print()/Debug.Printf → pmc_log --- */

static int Hook_LogPrintf(lua_State *L) {
    static volatile LONG s_firstCall = 0;
    LuaTValue *top = NULL, *base = NULL;
    int nargs = 0;
    char buf[2048];
    int pos = 0;
    int i;

    /* Cheap pre-filter: the shared stub is called by ~700 funcs, most NOT Lua
     * C functions. A lua_State* is a heap pointer — aligned and not tiny. Reject
     * implausible args before any VirtualQuery so non-Lua callers cost ~nothing.
     * This replicates the stub's behaviour (return 0) for everyone else. */
    if ((ULONG_PTR)L < 0x10000 || ((ULONG_PTR)L & 3)) return 0;

    /* Crash-survivable proof the hook is actually entered (flushed once). */
    if (InterlockedCompareExchange(&s_firstCall, 1, 0) == 0) {
        pmc_log("lualog", "first stripped-log call intercepted — hook live (arg=0x%08X)",
                (unsigned)(DWORD_PTR)L);
        pmc_log_flush();
    }
    if (!ResolvePrintStack(L, &top, &base, &nargs) || nargs < 1) return 0;

    /* Re-entrancy guard: a logged line must never trigger another logged line. */
    if (InterlockedCompareExchange(&g_inPrintHook, 1, 0) != 0) return 0;

    for (i = 0; i < nargs && pos < (int)sizeof(buf) - 64; i++) {
        LuaTValue arg;

        if (i > 0 && pos < (int)sizeof(buf) - 1) buf[pos++] = '\t';

        /* base..base+nargs was validated as one readable span in
         * ResolvePrintStack — no per-arg VirtualQuery needed here. */
        arg = *(base + i);

        switch (arg.tt) {
            case 0: /* nil */
                memcpy(buf + pos, "nil", 3); pos += 3;
                break;
            case LUA_TBOOLEAN:
                if (arg.value) { memcpy(buf + pos, "true", 4);  pos += 4; }
                else           { memcpy(buf + pos, "false", 5); pos += 5; }
                break;
            case 2: /* lightuserdata */
                pos += wsprintfA(buf + pos, "lightuserdata:0x%08X", arg.value);
                break;
            case LUA_TNUMBER: {
                float fval;
                memcpy(&fval, &arg.value, sizeof(float));
                if (fval == (float)(int)fval && fval > -100000 && fval < 100000)
                    pos += wsprintfA(buf + pos, "%d", (int)fval);
                else
                    pos += wsprintfA(buf + pos, "%f", (double)fval);
                break;
            }
            case LUA_TSTRING: {
                char chunk[256];
                int slen = SafeCopyTString(arg.value, chunk, (int)sizeof(chunk));
                if (slen > 0) {
                    int remaining = (int)sizeof(buf) - pos - 1;
                    if (slen > remaining) slen = remaining;
                    memcpy(buf + pos, chunk, slen); pos += slen;
                } else if (!arg.value) {
                    memcpy(buf + pos, "(null string)", 13); pos += 13;
                } else {
                    memcpy(buf + pos, "(bad string)", 12); pos += 12;
                }
                break;
            }
            case 5: pos += wsprintfA(buf + pos, "table:0x%08X", arg.value); break;
            case 6: pos += wsprintfA(buf + pos, "function:0x%08X", arg.value); break;
            case 7: pos += wsprintfA(buf + pos, "userdata:0x%08X", arg.value); break;
            case 8: pos += wsprintfA(buf + pos, "thread:0x%08X", arg.value); break;
            default:
                pos += wsprintfA(buf + pos, "?type%d:0x%08X", arg.tt, arg.value);
                break;
        }
    }
    buf[pos] = '\0';

    pmc_log("lua", "%s", buf);
    MaybeTagMilestone(buf);

    InterlockedExchange(&g_inPrintHook, 0);
    return 0; /* print/Debug.Printf push no results */
}

/* --- Installation: MinHook the shared stub (NO .rdata writes) ---
 *
 * We detour the stub's CODE at 0x006D5640. Registration tables stay pristine,
 * so SecuROM anti-tamper isn't tripped (a .rdata slot patch crashed early init
 * before our hook ran; a .text MinHook is tolerated — compat_hooks proves it).
 * Hook_LogPrintf is reached via MinHook's jmp with the caller's cdecl frame,
 * so its first param L == the stub's first stack arg ([esp+4]); for Lua print
 * callers that's the lua_State*, for everything else the pre-filter rejects it
 * and we return 0 exactly like the original no-op. We never call the original
 * (it only did `xor eax,eax; ret`), so the trampoline goes unused. */

static lua_CFunction g_origStub = NULL;  /* MinHook trampoline (unused no-op) */

int InstallLuaLogHook(void) {
    MH_STATUS st;

    /* Already initialized by InstallCompatHooks; init defensively for the
     * PMC_NO_COMPAT_HOOKS control build. */
    st = MH_Initialize();
    if (st != MH_OK && st != MH_ERROR_ALREADY_INITIALIZED) {
        pmc_log("lualog", "MH_Initialize failed: %s", MH_StatusToString(st));
        pmc_log_flush();
        return 0;
    }

    st = MH_CreateHook((LPVOID)VA_PRINT_STUB, (LPVOID)Hook_LogPrintf,
                       (LPVOID *)&g_origStub);
    if (st != MH_OK) {
        pmc_log("lualog", "MH_CreateHook(0x%08X) failed: %s",
                VA_PRINT_STUB, MH_StatusToString(st));
        pmc_log_flush();
        return 0;
    }

    st = MH_EnableHook((LPVOID)VA_PRINT_STUB);
    if (st != MH_OK) {
        pmc_log("lualog", "MH_EnableHook(0x%08X) failed: %s",
                VA_PRINT_STUB, MH_StatusToString(st));
        pmc_log_flush();
        return 0;
    }

    pmc_log("lualog", "Stripped-log capture installed: MinHook @0x%08X (shared "
            "print/Debug.Printf/subsystem stub). Watch sources [lua]/[world].",
            VA_PRINT_STUB);
    pmc_log_flush();  /* crash-survivable: this line on disk == install completed */
    return 1;
}
