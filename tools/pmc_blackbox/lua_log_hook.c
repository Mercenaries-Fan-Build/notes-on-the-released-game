/**
 * lua_log_hook.c — native capture of the game's Lua print/Debug.Printf stream.
 *
 * Ported from tools/dlc_enable_asi/dlc_enable.c (Hook_LogPrintf + the Lua-stack
 * readers + the luaL_Reg func-pointer patch), reduced to LOGGING ONLY. All the
 * bootstrap / net-hook / arena / streaming-fix machinery is intentionally left
 * in dlc_enable; pmc_bb just observes and records, matching its diagnostic role.
 *
 * Addresses are HARDCODED for the cracked retail EXE (53,482,288 bytes), the
 * same binary every other VA in pmc_bb targets. The Lua C API here is Lua 5.1.2
 * 32-bit (float numbers); the print func pointers ship pointing at the shared
 * stub 0x006D5640 (33 C0 C3 = xor eax,eax; ret).
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <string.h>

#include "lua_log_hook.h"

/* pmc_log is exported from pmc_blackbox.c (same DLL). */
extern void pmc_log(const char *source, const char *fmt, ...);

/* --- Verified VAs (cross-referenced with dlc_enable.c) --- */
#define VA_DEBUG_TABLE            0x00B98828
#define VA_DEBUG_PRINTF_FUNC_PTR  (VA_DEBUG_TABLE + 4) /* Debug.Printf luaL_Reg func ptr */
#define VA_BASE_PRINT_FUNC_PTR    0x00B9251C           /* luaopen_base "print" func ptr   */
#define VA_PRINT_STUB             0x006D5640           /* xor eax,eax; ret                */

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
    LuaTValue *top = NULL, *base = NULL;
    int nargs = 0;
    char buf[2048];
    int pos = 0;
    int i;

    if (!L) return 0;
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

/* --- Installation --- */

static BOOL VerifyRegPointsAtStub(DWORD reg_func_ptr_va) {
    DWORD func_va;
    BYTE *code;

    if (!PtrReadable((void *)reg_func_ptr_va, sizeof(DWORD))) return FALSE;
    func_va = *(DWORD *)reg_func_ptr_va;
    if (func_va != VA_PRINT_STUB) return FALSE;
    code = (BYTE *)func_va;
    if (!PtrReadable(code, 3)) return FALSE;
    return code[0] == 0x33 && code[1] == 0xC0 && code[2] == 0xC3;
}

static BOOL PatchLuaRegFuncPtr(DWORD reg_func_ptr_va, lua_CFunction new_func,
                              DWORD *out_old_func) {
    DWORD *site;
    DWORD old_prot;

    if (!new_func || !reg_func_ptr_va) return FALSE;
    site = (DWORD *)reg_func_ptr_va;
    if (!PtrReadable(site, sizeof(DWORD))) return FALSE;
    if (out_old_func) *out_old_func = *site;

    if (!VirtualProtect(site, sizeof(DWORD), PAGE_READWRITE, &old_prot)) {
        pmc_log("lualog", "ERROR: VirtualProtect failed for reg 0x%08X (err=%lu)",
                reg_func_ptr_va, (unsigned long)GetLastError());
        return FALSE;
    }
    *site = (DWORD)new_func;
    VirtualProtect(site, sizeof(DWORD), old_prot, &old_prot);
    return TRUE;
}

int InstallLuaLogHook(void) {
    int patched = 0;
    DWORD old_func = 0;

    if (VerifyRegPointsAtStub(VA_DEBUG_PRINTF_FUNC_PTR)) {
        if (PatchLuaRegFuncPtr(VA_DEBUG_PRINTF_FUNC_PTR, Hook_LogPrintf, &old_func)) {
            patched++;
            pmc_log("lualog", "Debug.Printf captured (reg 0x%08X: 0x%08X -> Hook_LogPrintf)",
                    VA_DEBUG_PRINTF_FUNC_PTR, old_func);
        }
    } else {
        pmc_log("lualog", "Debug.Printf reg 0x%08X not at stub — skip (already hooked?)",
                VA_DEBUG_PRINTF_FUNC_PTR);
    }

    if (VerifyRegPointsAtStub(VA_BASE_PRINT_FUNC_PTR)) {
        if (PatchLuaRegFuncPtr(VA_BASE_PRINT_FUNC_PTR, Hook_LogPrintf, &old_func)) {
            patched++;
            pmc_log("lualog", "print() captured (reg 0x%08X: 0x%08X -> Hook_LogPrintf)",
                    VA_BASE_PRINT_FUNC_PTR, old_func);
        }
    } else {
        pmc_log("lualog", "print() reg 0x%08X not at stub — skip (already hooked?)",
                VA_BASE_PRINT_FUNC_PTR);
    }

    pmc_log("lualog", "Lua message capture installed (%d/2 slots). Watch source [lua]/[world].",
            patched);
    return patched;
}
