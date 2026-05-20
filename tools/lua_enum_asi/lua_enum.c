/**
 * lua_enum.asi — Runtime Lua binding inventory for Mercenaries 2: World in Flames
 *
 * Loaded by ThirteenAG's Ultimate ASI Loader (dinput8.dll proxy). Captures the
 * main lua_State* during early Sys.* calls, resolves Lua 5.1 C API entry points
 * from the statically linked EXE, walks _G via lua_next(), and writes:
 *   scripts/lua_bindings_runtime.txt
 *   scripts/lua_bindings_runtime.json
 *
 * Also dumps static luaL_Reg tables from .rdata (registration-time inventory).
 *
 * Build (MinGW cross-compile):
 *   make -C tools/lua_enum_asi mingw
 *
 * Architecture: 32-bit (x86) Windows DLL — Mercenaries 2 PC is 32-bit.
 * Target EXE: cracked retail (~53 MB) with SecuROM removed; same .rdata layout
 * as documented in tools/dlc_enable_asi/dlc_enable.c.
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

/* --- Mercenaries 2 cracked EXE layout (image base 0x00400000) --- */

#define RDATA_START_VA      0x00B05000
#define RDATA_SIZE          0x000F1000
#define TEXT_START_VA       0x00401000
#define TEXT_SIZE           0x00703000
#define DATA_START_VA       0x00BF6000
#define DATA_SIZE           0x00DA4000

/* Known registration-table cluster (file offset + 0x400000) */
#define REG_TABLE_START_VA  0x00B98770
#define REG_TABLE_END_VA    0x00B99200

#define LUA_ENUM_DELAY_MS       10000
#define LUA_ENUM_CAPTURE_WAIT_MS 8000
#define LUA_ENUM_MAX_DEPTH      4
#define LUA_ENUM_MAX_VISITED      512
#define LUA_ENUM_MAX_BINDINGS     12000
#define LUA_ENUM_MAX_PATH         256

/* Lua 5.1 */
#define LUA_GLOBALSINDEX    (-10002)
#define LUA_TNONE           (-1)
#define LUA_TNIL            0
#define LUA_TBOOLEAN        1
#define LUA_TLIGHTUSERDATA  2
#define LUA_TNUMBER         3
#define LUA_TSTRING         4
#define LUA_TTABLE          5
#define LUA_TFUNCTION       6
#define LUA_TUSERDATA       7
#define LUA_TTHREAD         8

typedef struct lua_State lua_State;
typedef int (*lua_CFunction)(lua_State* L);

typedef void        (*pfn_lua_pushnil)(lua_State* L);
typedef void        (*pfn_lua_settop)(lua_State* L, int idx);
typedef int         (*pfn_lua_gettop)(lua_State* L);
typedef int         (*pfn_lua_type)(lua_State* L, int idx);
typedef const char* (*pfn_lua_tolstring)(lua_State* L, int idx, size_t* len);
typedef lua_CFunction (*pfn_lua_tocfunction)(lua_State* L, int idx);
typedef void        (*pfn_lua_getfield)(lua_State* L, int idx, const char* k);
typedef int         (*pfn_lua_next)(lua_State* L, int idx);

typedef struct {
    pfn_lua_pushnil pushnil;
    pfn_lua_settop settop;
    pfn_lua_gettop gettop;
    pfn_lua_type type_fn;
    pfn_lua_tolstring tolstring;
    pfn_lua_tocfunction tocfunction;
    pfn_lua_getfield getfield;
    pfn_lua_next next_fn;
} LuaApi;

typedef struct {
    char path[LUA_ENUM_MAX_PATH];
    char type_name[24];
    int lua_type;
    DWORD func_va;
    int depth;
    int source; /* 0=runtime, 1=static_rdata */
} BindingEntry;

typedef struct {
    DWORD table_ptr;
} VisitedTable;

static HMODULE g_hModule = NULL;
static HANDLE g_logHandle = INVALID_HANDLE_VALUE;
static char g_logPath[MAX_PATH];
static char g_outTxtPath[MAX_PATH];
static char g_outJsonPath[MAX_PATH];

static volatile LONG g_captureInstalled = 0;
static volatile LONG g_luaCaptured = 0;
static lua_State* g_L = NULL;

static lua_CFunction g_origIsDemoMode = NULL;
static lua_CFunction g_origGetLanguage = NULL;

static LuaApi g_api;
static BindingEntry g_bindings[LUA_ENUM_MAX_BINDINGS];
static int g_bindingCount = 0;
static VisitedTable g_visited[LUA_ENUM_MAX_VISITED];
static int g_visitedCount = 0;

/* --- Logging --- */

static void LogInit(void) {
    GetModuleFileNameA(g_hModule, g_logPath, MAX_PATH);
    char* dot = strrchr(g_logPath, '.');
    if (dot) {
        strcpy(dot, ".log");
    } else {
        strcat(g_logPath, ".log");
    }
    g_logHandle = CreateFileA(g_logPath, GENERIC_WRITE, FILE_SHARE_READ,
                              NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
}

static void Log(const char* fmt, ...) {
    if (g_logHandle == INVALID_HANDLE_VALUE) return;
    char buf[1024];
    va_list ap;
    va_start(ap, fmt);
    int len = wvsprintfA(buf, fmt, ap);
    va_end(ap);
    if (len > 0) {
        buf[len] = '\r';
        buf[len + 1] = '\n';
        DWORD written;
        WriteFile(g_logHandle, buf, len + 2, &written, NULL);
    }
}

static void LogClose(void) {
    if (g_logHandle != INVALID_HANDLE_VALUE) {
        CloseHandle(g_logHandle);
        g_logHandle = INVALID_HANDLE_VALUE;
    }
}

static void BuildOutputPaths(void) {
    char dir[MAX_PATH];
    GetModuleFileNameA(g_hModule, dir, MAX_PATH);
    char* slash = strrchr(dir, '\\');
    if (!slash) slash = strrchr(dir, '/');
    if (slash) {
        *(slash + 1) = '\0';
    } else {
        dir[0] = '\0';
    }
    wsprintfA(g_outTxtPath, "%slua_bindings_runtime.txt", dir);
    wsprintfA(g_outJsonPath, "%slua_bindings_runtime.json", dir);
}

/* --- Memory helpers --- */

static BOOL IsReadablePtr(const void* p, size_t n) {
    if (!p) return FALSE;
    return !IsBadReadPtr((void*)p, n);
}

static BOOL IsVaInRdata(DWORD va) {
    return va >= RDATA_START_VA && va < RDATA_START_VA + RDATA_SIZE;
}

static BOOL IsVaInText(DWORD va) {
    return va >= TEXT_START_VA && va < TEXT_START_VA + TEXT_SIZE;
}

static DWORD FindStringInRdata(const char* target) {
    BYTE* base = (BYTE*)RDATA_START_VA;
    size_t len = strlen(target);
    if (len == 0 || len >= RDATA_SIZE) return 0;
    for (DWORD i = 0; i + len < RDATA_SIZE; i++) {
        if (memcmp(base + i, target, len + 1) == 0) {
            return RDATA_START_VA + i;
        }
    }
    return 0;
}

static DWORD FindFunctionStart(DWORD code_va) {
    if (!IsVaInText(code_va)) return 0;
    BYTE* p = (BYTE*)code_va;
    DWORD start = code_va;
    for (int back = 0; back < 0x600; back++) {
        BYTE* q = p - back;
        if (!IsVaInText((DWORD)q)) break;
        if (q[0] == 0x55 && q[1] == 0x8B && (q[2] == 0xEC || q[2] == 0xE9)) {
            start = (DWORD)q;
            break;
        }
        if (q[0] == 0x53 && q[1] == 0x8B && q[2] == 0xDC) {
            start = (DWORD)q;
            break;
        }
    }
    return start;
}

static DWORD FindCodeXrefToVa(DWORD target_va) {
    BYTE* text = (BYTE*)TEXT_START_VA;
    BYTE pat[4];
    pat[0] = (BYTE)(target_va);
    pat[1] = (BYTE)(target_va >> 8);
    pat[2] = (BYTE)(target_va >> 16);
    pat[3] = (BYTE)(target_va >> 24);
    for (DWORD i = 0; i + 4 < TEXT_SIZE; i++) {
        if (memcmp(text + i, pat, 4) == 0) {
            return TEXT_START_VA + i;
        }
    }
    return 0;
}

static DWORD ResolveFuncFromErrorString(const char* err) {
    DWORD str_va = FindStringInRdata(err);
    if (!str_va) return 0;
    DWORD xref = FindCodeXrefToVa(str_va);
    if (!xref) return 0;
    return FindFunctionStart(xref);
}

static DWORD ResolveLuaNext(void) {
    DWORD f = ResolveFuncFromErrorString("invalid key to 'next'");
    if (f) return f;
    f = ResolveFuncFromErrorString("table overflow");
    return f;
}

static DWORD ResolveLuaGetfield(void) {
    BYTE* text = (BYTE*)TEXT_START_VA;
    for (DWORD i = 0; i + 5 < TEXT_SIZE; i++) {
        if (text[i] == 0xB9) {
            DWORD imm = *(DWORD*)(text + i + 1);
            if (imm == (DWORD)LUA_GLOBALSINDEX) {
                DWORD func = FindFunctionStart(TEXT_START_VA + i);
                if (func) {
                    BYTE* p = (BYTE*)func;
                    if (IsReadablePtr(p, 8) && p[0] == 0x55) {
                        return func;
                    }
                }
            }
        }
    }
    return 0;
}

static DWORD ResolveLuaType(void) {
    /* lua_type is a small function near lua_typename in the lapi cluster */
    DWORD f = ResolveFuncFromErrorString("no value");
    if (!f) return 0;
    f = FindFunctionStart(f - 0x40);
    if (f && IsVaInText(f)) return f;
    return ResolveFuncFromErrorString("value expected");
}

static DWORD ResolveNearCallTarget(DWORD func_va, int call_index) {
    BYTE* p = (BYTE*)func_va;
    int found = 0;
    DWORD i;
    if (!IsVaInText(func_va)) return 0;
    for (i = 0; i + 5 < 0x200; i++) {
        if (p[i] == 0xE8) {
            int rel = *(int*)(p + i + 1);
            DWORD dst = func_va + i + 5 + rel;
            if (IsVaInText(dst)) {
                if (found == call_index) return dst;
                found++;
            }
        }
    }
    return 0;
}

static BOOL ResolveLuaAPI(void) {
    DWORD next_fn, getfield, type_fn, settop_cand, pushnil_cand;
    int resolved = 0;

    memset(&g_api, 0, sizeof(g_api));
    next_fn = ResolveLuaNext();
    getfield = ResolveLuaGetfield();
    type_fn = ResolveLuaType();

    if (next_fn) {
        g_api.next_fn = (pfn_lua_next)next_fn;
        resolved++;
        Log("Resolved lua_next at 0x%08X", next_fn);
    }
    if (getfield) {
        g_api.getfield = (pfn_lua_getfield)getfield;
        resolved++;
        Log("Resolved lua_getfield at 0x%08X", getfield);
    }
    if (type_fn) {
        g_api.type_fn = (pfn_lua_type)type_fn;
        resolved++;
        Log("Resolved lua_type at 0x%08X", type_fn);
    }

    /* luaB_next calls pushnil/settop/gettop near the next_fn cluster */
    if (next_fn) {
        pushnil_cand = ResolveNearCallTarget(next_fn - 0x200, 0);
        settop_cand = ResolveNearCallTarget(next_fn - 0x200, 1);
        if (pushnil_cand && IsVaInText(pushnil_cand)) {
            g_api.pushnil = (pfn_lua_pushnil)pushnil_cand;
            resolved++;
            Log("Resolved lua_pushnil (heuristic) at 0x%08X", pushnil_cand);
        }
    }

    /* Common cluster: lua_settop / lua_gettop often live near lua_getfield */
    if (getfield) {
        settop_cand = FindFunctionStart(getfield - 0x80);
        if (settop_cand && settop_cand != getfield) {
            g_api.settop = (pfn_lua_settop)settop_cand;
            g_api.gettop = (pfn_lua_gettop)(settop_cand - 0x30);
            resolved++;
            Log("Resolved lua_settop (heuristic) at 0x%08X", settop_cand);
        }
    }

    /* lua_tolstring: "string expected" xrefs */
    {
        DWORD tol = ResolveFuncFromErrorString("string expected");
        if (tol) {
            g_api.tolstring = (pfn_lua_tolstring)tol;
            resolved++;
            Log("Resolved lua_tolstring (heuristic) at 0x%08X", tol);
        }
    }

    /* lua_tocfunction: small wrapper near lua_type */
    if (type_fn) {
        DWORD toc = FindFunctionStart(type_fn + 0x40);
        if (toc && toc != type_fn) {
            g_api.tocfunction = (pfn_lua_tocfunction)toc;
            resolved++;
            Log("Resolved lua_tocfunction (heuristic) at 0x%08X", toc);
        }
    }

    Log("Lua API resolution: %d symbols (need lua_next+getfield+settop+pushnil for runtime walk)",
        resolved);
    return g_api.next_fn && g_api.getfield && g_api.settop && g_api.pushnil;
}

/* --- lua_State capture (registration-table redirect) --- */

static lua_CFunction FindLuaFuncForString(DWORD string_va) {
    BYTE* base = (BYTE*)RDATA_START_VA;
    DWORD i;
    for (i = 0; i + 8 < RDATA_SIZE; i += 4) {
        DWORD val = *(DWORD*)(base + i);
        if (val == string_va) {
            DWORD func_va = *(DWORD*)(base + i + 4);
            if (IsVaInText(func_va)) {
                return (lua_CFunction)func_va;
            }
        }
    }
    return NULL;
}

static BOOL PatchRegFuncPointer(DWORD string_va, lua_CFunction new_func) {
    BYTE* rdata = (BYTE*)RDATA_START_VA;
    DWORD i;
    for (i = 0; i + 8 < RDATA_SIZE; i += 4) {
        if (*(DWORD*)(rdata + i) == string_va) {
            DWORD* slot = (DWORD*)(rdata + i + 4);
            DWORD func_va = *slot;
            if (!IsVaInText(func_va)) continue;
            DWORD old_prot;
            if (!VirtualProtect(slot, 4, PAGE_READWRITE, &old_prot)) {
                return FALSE;
            }
            *slot = (DWORD)new_func;
            VirtualProtect(slot, 4, old_prot, &old_prot);
            return TRUE;
        }
    }
    return FALSE;
}

static int Hook_CaptureLua(lua_State* L) {
    if (!g_L && L) {
        g_L = L;
        InterlockedExchange(&g_luaCaptured, 1);
        Log("Captured lua_State* = 0x%08X", (DWORD)L);
    }
    return 0;
}

static int Hook_CaptureIsDemoMode(lua_State* L) {
    Hook_CaptureLua(L);
    if (g_origIsDemoMode) {
        return g_origIsDemoMode(L);
    }
    return 0;
}

static int Hook_CaptureGetLanguage(lua_State* L) {
    Hook_CaptureLua(L);
    if (g_origGetLanguage) {
        return g_origGetLanguage(L);
    }
    return 0;
}

static void InstallCaptureHooks(void) {
    DWORD str_demo, str_lang;

    if (InterlockedCompareExchange(&g_captureInstalled, 1, 0) != 0) {
        return;
    }

    str_demo = FindStringInRdata("IsDemoMode");
    if (str_demo) {
        g_origIsDemoMode = FindLuaFuncForString(str_demo);
        if (g_origIsDemoMode) {
            if (PatchRegFuncPointer(str_demo, Hook_CaptureIsDemoMode)) {
                Log("Capture hook installed on IsDemoMode (orig=0x%08X)",
                    (DWORD)g_origIsDemoMode);
            }
        }
    }

    str_lang = FindStringInRdata("GetLanguage");
    if (str_lang) {
        g_origGetLanguage = FindLuaFuncForString(str_lang);
        if (g_origGetLanguage) {
            if (PatchRegFuncPointer(str_lang, Hook_CaptureGetLanguage)) {
                Log("Capture hook installed on GetLanguage (orig=0x%08X)",
                    (DWORD)g_origGetLanguage);
            }
        }
    }
}

/* --- Binding inventory --- */

static const char* LuaTypeName(int t) {
    switch (t) {
        case LUA_TNIL: return "nil";
        case LUA_TBOOLEAN: return "boolean";
        case LUA_TNUMBER: return "number";
        case LUA_TSTRING: return "string";
        case LUA_TTABLE: return "table";
        case LUA_TFUNCTION: return "function";
        case LUA_TUSERDATA: return "userdata";
        case LUA_TTHREAD: return "thread";
        case LUA_TLIGHTUSERDATA: return "lightuserdata";
        default: return "unknown";
    }
}

static BOOL PathExists(const char* path) {
    int i;
    for (i = 0; i < g_bindingCount; i++) {
        if (strcmp(g_bindings[i].path, path) == 0) {
            return TRUE;
        }
    }
    return FALSE;
}

static BOOL AddBinding(const char* path, const char* type_name, int lua_type,
                       DWORD func_va, int depth, int source) {
    if (g_bindingCount >= LUA_ENUM_MAX_BINDINGS) return FALSE;
    if (PathExists(path)) return TRUE;
    {
        BindingEntry* e = &g_bindings[g_bindingCount++];
        strncpy(e->path, path, LUA_ENUM_MAX_PATH - 1);
        e->path[LUA_ENUM_MAX_PATH - 1] = '\0';
        strncpy(e->type_name, type_name, sizeof(e->type_name) - 1);
        e->type_name[sizeof(e->type_name) - 1] = '\0';
        e->lua_type = lua_type;
        e->func_va = func_va;
        e->depth = depth;
        e->source = source;
    }
    return TRUE;
}

static BOOL IsVisitedTable(DWORD table_ptr) {
    int i;
    for (i = 0; i < g_visitedCount; i++) {
        if (g_visited[i].table_ptr == table_ptr) return TRUE;
    }
    return FALSE;
}

static BOOL MarkVisitedTable(DWORD table_ptr) {
    if (g_visitedCount >= LUA_ENUM_MAX_VISITED) return FALSE;
    if (IsVisitedTable(table_ptr)) return TRUE;
    g_visited[g_visitedCount++].table_ptr = table_ptr;
    return TRUE;
}

static BOOL IsIdentChar(char c) {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
           (c >= '0' && c <= '9') || c == '_';
}

static BOOL IsValidBindingName(const char* s) {
    size_t len;
    size_t i;
    if (!s || !IsReadablePtr(s, 1)) return FALSE;
    len = strlen(s);
    if (len == 0 || len > 96) return FALSE;
    if (!IsIdentChar(s[0]) && s[0] != '_') return FALSE;
    for (i = 0; i < len; i++) {
        if (!IsIdentChar(s[i])) return FALSE;
    }
    return TRUE;
}

static DWORD Get TValuePointerAtIndex(lua_State* L, int idx) {
    typedef struct { void* value; int tt; } TValue;
    typedef TValue* StkId;
    StkId* top_ptr = (StkId*)((BYTE*)L + 8);
    StkId top = *top_ptr;
    StkId base = *(StkId*)((BYTE*)L + 0x0C);
    StkId slot;
    (void)base;
    if (!top_ptr || !top) return 0;
    if (idx < 0) slot = top + idx;
    else slot = (StkId)0;
    (void)slot;
    if (idx == -1) slot = top - 1;
    else if (idx == -2) slot = top - 2;
    else return 0;
    if (!IsReadablePtr(slot, sizeof(TValue))) return 0;
    if (slot->tt != LUA_TTABLE) return 0;
    return (DWORD)slot->value;
}

static void ScanRegTableAt(DWORD table_va, const char* namespace_prefix) {
    BYTE* p = (BYTE*)table_va;
    DWORD end = table_va + 0x2000;
    int consecutive = 0;

    while ((DWORD)p + 8 <= end) {
        DWORD name_va = *(DWORD*)p;
        DWORD func_va = *(DWORD*)(p + 4);
        const char* name;
        char path[LUA_ENUM_MAX_PATH];

        if (name_va == 0 && func_va == 0) break;
        if (!IsVaInRdata(name_va) || !IsVaInText(func_va)) {
            if (consecutive >= 3) break;
            consecutive = 0;
            p += 4;
            continue;
        }
        name = (const char*)name_va;
        if (!IsValidBindingName(name)) {
            if (consecutive >= 3) break;
            consecutive = 0;
            p += 4;
            continue;
        }
        consecutive++;
        if (namespace_prefix && namespace_prefix[0]) {
            wsprintfA(path, "%s.%s", namespace_prefix, name);
        } else {
            strncpy(path, name, sizeof(path) - 1);
            path[sizeof(path) - 1] = '\0';
        }
        AddBinding(path, "function", LUA_TFUNCTION, func_va, 0, 1);
        p += 8;
    }
}

static void EnumerateStaticRdataTables(void) {
    int added_before = g_bindingCount;

    Log("Static luaL_Reg scan (known cluster 0x%08X..0x%08X)...",
        REG_TABLE_START_VA, REG_TABLE_END_VA);
    ScanRegTableAt(REG_TABLE_START_VA, NULL);

    /* Namespace tables referenced by adjacent string literals (Sys, Net, ...) */
    {
        static const char* namespaces[] = {
            "Sys", "Net", "Object", "Player", "Gui", "Sound", "Event",
            "Debug", "Boundary", "Save", "Weapon", "Ai", NULL
        };
        int i;
        for (i = 0; namespaces[i]; i++) {
            DWORD str_va = FindStringInRdata(namespaces[i]);
            DWORD j;
            BYTE* rdata;
            if (!str_va) continue;
            rdata = (BYTE*)RDATA_START_VA;
            for (j = 0; j + 8 < RDATA_SIZE; j += 4) {
                if (*(DWORD*)(rdata + j) == str_va) {
                    DWORD maybe_table = RDATA_START_VA + j + 8;
                    ScanRegTableAt(maybe_table, namespaces[i]);
                    break;
                }
            }
        }
    }

    Log("Static scan added %d bindings (total=%d)",
        g_bindingCount - added_before, g_bindingCount);
}

static void AppendPath(char* out, size_t out_sz, const char* prefix, const char* key) {
    if (prefix[0]) {
        wsprintfA(out, "%s.%s", prefix, key);
    } else {
        strncpy(out, key, out_sz - 1);
        out[out_sz - 1] = '\0';
    }
}

static void WalkTableAt(lua_State* L, int tbl_idx, const char* prefix, int depth) {
    const char* key;
    int t_key, t_val;
    DWORD tbl_ptr;

    if (!g_api.next_fn || !g_api.pushnil || !g_api.settop || !g_api.type_fn) return;
    if (depth >= LUA_ENUM_MAX_DEPTH) return;

    tbl_ptr = GetTValuePointerAtIndex(L, tbl_idx);
    if (tbl_ptr && IsVisitedTable(tbl_ptr)) return;
    if (tbl_ptr) MarkVisitedTable(tbl_ptr);

    /* Table at rel index (e.g. -1): pushnil moves it to -2 for lua_next */
    if (tbl_idx < 0 && tbl_idx > -10000) {
        g_api.pushnil(L);
        tbl_idx = tbl_idx - 1;
    } else {
        g_api.pushnil(L);
    }

    while (g_api.next_fn(L, tbl_idx)) {
        t_key = g_api.type_fn(L, -2);
        t_val = g_api.type_fn(L, -1);
        if (t_key == LUA_TSTRING && g_api.tolstring) {
            key = g_api.tolstring(L, -2, NULL);
            if (key && IsValidBindingName(key)) {
                char path[LUA_ENUM_MAX_PATH];
                DWORD fva = 0;
                AppendPath(path, sizeof(path), prefix, key);
                if (t_val == LUA_TFUNCTION && g_api.tocfunction) {
                    lua_CFunction fn = g_api.tocfunction(L, -1);
                    if (fn) fva = (DWORD)fn;
                }
                AddBinding(path, LuaTypeName(t_val), t_val, fva, depth, 0);
                if (t_val == LUA_TTABLE) {
                    WalkTableAt(L, -1, path, depth + 1);
                }
            }
        }
        g_api.settop(L, -1);
    }

    /* Pop the table (and pushnil) used for iteration */
    if (g_api.gettop) {
        g_api.settop(L, g_api.gettop(L) - 2);
    } else {
        g_api.settop(L, -3);
    }
}

static void EnumerateGlobalsRuntime(lua_State* L) {
    const char* key;
    int t_key, t_val;

    if (!g_api.next_fn || !g_api.pushnil || !g_api.settop || !g_api.type_fn) return;

    Log("Runtime lua_next walk on _G (depth limit %d)...", LUA_ENUM_MAX_DEPTH);
    g_visitedCount = 0;

    g_api.pushnil(L);
    while (g_api.next_fn(L, LUA_GLOBALSINDEX)) {
        t_key = g_api.type_fn(L, -2);
        t_val = g_api.type_fn(L, -1);
        if (t_key == LUA_TSTRING && g_api.tolstring) {
            key = g_api.tolstring(L, -2, NULL);
            if (key && IsValidBindingName(key)) {
                DWORD fva = 0;
                if (t_val == LUA_TFUNCTION && g_api.tocfunction) {
                    lua_CFunction fn = g_api.tocfunction(L, -1);
                    if (fn) fva = (DWORD)fn;
                }
                AddBinding(key, LuaTypeName(t_val), t_val, fva, 0, 0);
                if (t_val == LUA_TTABLE) {
                    WalkTableAt(L, -1, key, 1);
                }
            }
        }
        g_api.settop(L, -1);
    }
}

static void WriteOutputFiles(BOOL runtime_ok) {
    HANDLE hf;
    DWORD written;
    int i;
    SYSTEMTIME st;
    char line[512];

    GetLocalTime(&st);

    hf = CreateFileA(g_outTxtPath, GENERIC_WRITE, FILE_SHARE_READ,
                     NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hf == INVALID_HANDLE_VALUE) {
        Log("ERROR: cannot write %s (err=%lu)", g_outTxtPath, GetLastError());
        return;
    }

    wsprintfA(line,
              "# Mercenaries 2 Lua bindings (runtime inventory)\r\n"
              "# Generated by lua_enum.asi\r\n"
              "# local_time=%04u-%02u-%02u %02u:%02u:%02u\r\n"
              "# lua_state=0x%08X\r\n"
              "# runtime_walk=%s\r\n"
              "# binding_count=%d\r\n"
              "# Columns: path | type | func_va | depth | source\r\n"
              "#   source: runtime = lua_next snapshot, static = .rdata luaL_Reg scan\r\n\r\n",
              (unsigned)st.wYear, (unsigned)st.wMonth, (unsigned)st.wDay,
              (unsigned)st.wHour, (unsigned)st.wMinute, (unsigned)st.wSecond,
              (DWORD)g_L, runtime_ok ? "yes" : "no", g_bindingCount);
    WriteFile(hf, line, (DWORD)strlen(line), &written, NULL);

    for (i = 0; i < g_bindingCount; i++) {
        BindingEntry* e = &g_bindings[i];
        wsprintfA(line, "%s | %s | 0x%08X | depth=%d | %s\r\n",
                  e->path, e->type_name, e->func_va, e->depth,
                  e->source ? "static" : "runtime");
        WriteFile(hf, line, (DWORD)strlen(line), &written, NULL);
    }
    CloseHandle(hf);
    Log("Wrote %s (%d bindings)", g_outTxtPath, g_bindingCount);

    hf = CreateFileA(g_outJsonPath, GENERIC_WRITE, FILE_SHARE_READ,
                     NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hf == INVALID_HANDLE_VALUE) {
        Log("ERROR: cannot write %s (err=%lu)", g_outJsonPath, GetLastError());
        return;
    }

    wsprintfA(line,
              "{\r\n"
              "  \"generator\": \"lua_enum.asi\",\r\n"
              "  \"lua_state\": \"0x%08X\",\r\n"
              "  \"runtime_walk\": %s,\r\n"
              "  \"binding_count\": %d,\r\n"
              "  \"bindings\": [\r\n",
              (DWORD)g_L, runtime_ok ? "true" : "false", g_bindingCount);
    WriteFile(hf, line, (DWORD)strlen(line), &written, NULL);

    for (i = 0; i < g_bindingCount; i++) {
        BindingEntry* e = &g_bindings[i];
        wsprintfA(line,
                  "    {\"path\": \"%s\", \"type\": \"%s\", \"lua_type\": %d,"
                  " \"func_va\": \"0x%08X\", \"depth\": %d, \"source\": \"%s\"}%s\r\n",
                  e->path, e->type_name, e->lua_type, e->func_va, e->depth,
                  e->source ? "static" : "runtime",
                  (i + 1 < g_bindingCount) ? "," : "");
        WriteFile(hf, line, (DWORD)strlen(line), &written, NULL);
    }

    WriteFile(hf, "  ]\r\n}\r\n", 8, &written, NULL);
    CloseHandle(hf);
    Log("Wrote %s", g_outJsonPath);
}

/* --- Worker thread --- */

static DWORD WINAPI EnumThread(LPVOID param) {
    BOOL runtime_ok = FALSE;
    DWORD wait_start;
    (void)param;

    Log("=== lua_enum.asi ===");
    BuildOutputPaths();
    Log("Output: %s", g_outTxtPath);
    Log("Output: %s", g_outJsonPath);

    /* Install capture hooks early so Sys.* calls during init are observed */
    Sleep(2000);
    InstallCaptureHooks();

    Log("Worker: waiting %d ms total before enumeration...", LUA_ENUM_DELAY_MS);
    Sleep(LUA_ENUM_DELAY_MS > 2000 ? LUA_ENUM_DELAY_MS - 2000 : 1000);

    wait_start = GetTickCount();
    while (!g_luaCaptured &&
           (GetTickCount() - wait_start) < (DWORD)LUA_ENUM_CAPTURE_WAIT_MS) {
        Sleep(100);
    }

    if (!g_L) {
        Log("WARNING: lua_State* not captured (Sys hooks may not have fired yet)");
    } else {
        Log("lua_State* ready at 0x%08X", (DWORD)g_L);
    }

    g_bindingCount = 0;

    if (g_L && ResolveLuaAPI()) {
        __try {
            EnumerateGlobalsRuntime(g_L);
            runtime_ok = TRUE;
            Log("Runtime enumeration complete (%d bindings so far)", g_bindingCount);
        } __except (EXCEPTION_EXECUTE_HANDLER) {
            Log("ERROR: runtime enumeration crashed (exception) — skipping");
        }
    } else {
        Log("Runtime walk skipped (missing L or unresolved Lua API)");
    }

    __try {
        EnumerateStaticRdataTables();
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        Log("ERROR: static .rdata scan crashed (exception)");
    }

    WriteOutputFiles(runtime_ok);
    Log("=== lua_enum.asi finished ===");
    LogClose();
    return 0;
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
    (void)lpvReserved;
    if (fdwReason == DLL_PROCESS_ATTACH) {
        g_hModule = (HMODULE)hinstDLL;
        DisableThreadLibraryCalls(hinstDLL);
        LogInit();
        Log("=== lua_enum.asi loaded ===");
#ifdef LUA_ENUM_MSGBOX
        MessageBoxA(NULL,
                    "lua_enum.asi loaded.\n\n"
                    "After ~10 seconds in-game, check scripts/ for\n"
                    "lua_bindings_runtime.txt and .json",
                    "Lua Enum Plugin", MB_OK | MB_ICONINFORMATION);
#endif
        CreateThread(NULL, 0, EnumThread, NULL, 0, NULL);
    }
    return TRUE;
}
