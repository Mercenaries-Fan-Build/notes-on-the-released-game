/**
 * mercs2_probe.asi — Runtime research probe for Mercenaries 2: World in Flames
 *
 * Standalone ASI plugin (NOT coupled to dlc_enable.asi). Loaded by pmc_bb.dll /
 * Ultimate ASI Loader from <game>/scripts/.
 *
 * Captures lua_State* via early Sys.* registration hooks, then runs probe modules
 * that write JSON to scripts/probe_results/:
 *   lua_state_layout.json
 *   lua_api_signatures.json
 *   lua_bindings_deep.json  (primary cluster only; paths use verified ns or table@0xVA)
 *   game_objects.json
 *   memory_map.json
 *
 * Build: make -C tools/mercs2_probe mingw
 *        make mercs2-probe OUTPUT=./output
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <psapi.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

/* --- EXE layout (cracked retail 53,482,288 bytes, image base 0x00400000) --- */

#define EXPECTED_EXE_SIZE       53482288
#define IMAGE_BASE              0x00400000

#define RDATA_START_VA          0x00B05000
#define RDATA_SIZE              0x000F1000
#define TEXT_START_VA           0x00401000
#define TEXT_SIZE               0x00703000
#define DATA_START_VA           0x00BF6000
#define DATA_SIZE               0x00DA4000

/* Cracked EXE: DRM init never sets this; spawn uses terrain validation when == 1.
 * Same fix as tools/pmc_blackbox/pmc_blackbox.c FixSpawnValidation(). */
#define SPAWN_VALIDATION_FLAG_VA  0x00DFBD74

#define REG_TABLE_START_VA      0x00B98770
#define REG_TABLE_SCAN_END_VA   0x00B9AA38

typedef struct {
    DWORD table_va;
    const char* namespace;
} VerifiedRegTable;

/* CONFIRMED/CERTAIN only (docs/lua_engine_bindings_audit_deep_dive.md §1.4). */
static const VerifiedRegTable VERIFIED_REG_TABLES[] = {
    { 0x00B987F8, "Event" },
    { 0x00B98828, "Debug" },
    { 0x00B98860, "Weapon" },
    { 0x00B988B0, "VO" },
    { 0x00B98918, "Vehicle" },
    { 0x00B98A78, "Sys" },
    { 0x00B98C98, "Sound" },
    { 0x00B98F64, "Faction" },
    { 0x00B98FC0, "Player" },
    { 0x00B99328, "Pg" },
    { 0x00B99608, "Object" },
    { 0x00B998D0, "Net" },
    { 0x00B99C78, "LTI" },
    { 0x00B99FF8, "Gui" },
    { 0x00B9A7D8, "Camera" },
    { 0x00B9A854, "_SYS" },
    { 0x00B9A938, "Ai" },
};

#define PROBE_DELAY_MS          8000
#define PROBE_CAPTURE_WAIT_MS   120000
#define PROBE_MAX_DEPTH         4
#define PROBE_MAX_VISITED       512
#define PROBE_MAX_BINDINGS      12000
#define PROBE_MAX_PATH          256
#define PROBE_MAX_CALLERS       16
#define PROBE_MAX_OBJECT_SAMPLES 32

/* lua_next/_G walk MUST run on the game's Lua thread — never from ProbeThread.
 * Default off; set to 1 only with game-thread dispatch (not implemented yet). */
#ifndef MERCS2_PROBE_RUNTIME_WALK
#define MERCS2_PROBE_RUNTIME_WALK 0
#endif

/* Do not patch GetPosition — reg patch persists and can break unrelated bindings. */
#ifndef MERCS2_PROBE_OBJECT_HOOK
#define MERCS2_PROBE_OBJECT_HOOK 0
#endif

/* Documented Lua C API VAs (verify_lua_vas.py / dlc_enable.c) */
#define VA_LUAL_LOADBUFFER      0x00860240
#define VA_LUA_PCALL            0x0085DF50
#define VA_LUAB_LOADSTRING      0x00860FC0
#define VA_LUAB_PCALL           0x008615F0
#define VA_PRINT_STUB           0x006D5640
#define VA_LUAL_TYPERROR        0x0085F050
#define VA_LUAD_PCALL           0x00868AD0

/* Documented lua_State offsets (dlc_enable.c) */
#define OFF_L_TOP               0x08
#define OFF_L_BASE              0x0C
#define OFF_L_L_G               0x10
#define OFF_L_CI                0x14
#define OFF_L_STACK_LAST        0x1C
#define OFF_L_STACK             0x20
#define TSTRING_DATA_OFF        16

#define LUA_GLOBALSINDEX        (-10002)
#define LUA_TNIL                0
#define LUA_TBOOLEAN            1
#define LUA_TNUMBER             3
#define LUA_TSTRING             4
#define LUA_TTABLE              5
#define LUA_TFUNCTION           6
#define LUA_TUSERDATA           7
#define LUA_TLIGHTUSERDATA      2

typedef struct lua_State lua_State;
typedef int (*lua_CFunction)(lua_State* L);

typedef void        (*pfn_lua_pushnil)(lua_State* L);
typedef void        (*pfn_lua_settop)(lua_State* L, int idx);
typedef int         (*pfn_lua_gettop)(lua_State* L);
typedef int         (*pfn_lua_type)(lua_State* L, int idx);
typedef const char* (*pfn_lua_tolstring)(lua_State* L, int idx, size_t* len);
typedef lua_CFunction (*pfn_lua_tocfunction)(lua_State* L, int idx);
typedef int         (*pfn_lua_next)(lua_State* L, int idx);
typedef void        (*pfn_lua_getfield)(lua_State* L, int idx, const char* k);

typedef struct {
    pfn_lua_pushnil pushnil;
    pfn_lua_settop settop;
    pfn_lua_gettop gettop;
    pfn_lua_type type_fn;
    pfn_lua_tolstring tolstring;
    pfn_lua_tocfunction tocfunction;
    pfn_lua_next next_fn;
    pfn_lua_getfield getfield;
} LuaApi;

typedef struct { DWORD value; DWORD tt; } LuaTValue;

typedef struct {
    char path[PROBE_MAX_PATH];
    char type_name[24];
    int lua_type;
    DWORD func_va;
    int depth;
    int source;
    int ret_heuristic;
    int arg_heuristic;
} BindingEntry;

typedef struct {
    DWORD userdata_ptr;
    DWORD sample_count;
    DWORD dword_offsets[64];
    DWORD dword_values[64];
} ObjectSample;

/* --- Globals --- */

static HMODULE g_hModule = NULL;
static HANDLE g_logHandle = INVALID_HANDLE_VALUE;
static char g_logPath[MAX_PATH];
static char g_outDir[MAX_PATH];

static volatile LONG g_captureInstalled = 0;
static volatile LONG g_luaCaptured = 0;
static lua_State* g_L = NULL;

static lua_CFunction g_origIsDemoMode = NULL;
static lua_CFunction g_origGetLanguage = NULL;
static lua_CFunction g_origIsOnlineConnected = NULL;
static lua_CFunction g_origGetPosition = NULL;
static volatile LONG g_objectHookFired = 0;

static LuaApi g_api;
static BindingEntry g_bindings[PROBE_MAX_BINDINGS];
static int g_bindingCount = 0;
static DWORD g_visited[PROBE_MAX_VISITED];
static int g_visitedCount = 0;

static ObjectSample g_objectSamples[PROBE_MAX_OBJECT_SAMPLES];
static int g_objectSampleCount = 0;

static BOOL g_exeVerified = FALSE;

typedef struct {
    DWORD* slot;
    DWORD orig_func;
} RegPatchRestore;

static RegPatchRestore g_regRestore[12];
static int g_regRestoreCount = 0;

/* --- Logging --- */

static void LogInit(void) {
    GetModuleFileNameA(g_hModule, g_logPath, MAX_PATH);
    {
        char* dot = strrchr(g_logPath, '.');
        if (dot) strcpy(dot, ".log");
        else strcat(g_logPath, ".log");
    }
    g_logHandle = CreateFileA(g_logPath, GENERIC_WRITE, FILE_SHARE_READ,
                              NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
}

static void Log(const char* fmt, ...) {
    char buf[1024];
    va_list ap;
    int len;
    DWORD written;

    if (g_logHandle == INVALID_HANDLE_VALUE) return;
    va_start(ap, fmt);
    len = wvsprintfA(buf, fmt, ap);
    va_end(ap);
    if (len > 0) {
        buf[len] = '\r';
        buf[len + 1] = '\n';
        WriteFile(g_logHandle, buf, len + 2, &written, NULL);
        FlushFileBuffers(g_logHandle);
    }
}

static void LogClose(void) {
    if (g_logHandle != INVALID_HANDLE_VALUE) {
        CloseHandle(g_logHandle);
        g_logHandle = INVALID_HANDLE_VALUE;
    }
}

/* --- Memory helpers --- */

static BOOL PtrReadable(const void* p, SIZE_T n) {
    MEMORY_BASIC_INFORMATION mbi;
    ULONG_PTR addr;
    ULONG_PTR end;

    if (!p || n == 0) return FALSE;
    if (VirtualQuery(p, &mbi, sizeof(mbi)) == 0) return FALSE;
    if (mbi.State != MEM_COMMIT) return FALSE;
    if (mbi.Protect & (PAGE_NOACCESS | PAGE_GUARD)) return FALSE;
    addr = (ULONG_PTR)p;
    end = (ULONG_PTR)mbi.BaseAddress + mbi.RegionSize;
    return (addr + n <= end);
}

static BOOL IsVaInRdata(DWORD va) {
    return va >= RDATA_START_VA && va < RDATA_START_VA + RDATA_SIZE;
}

static BOOL IsVaInText(DWORD va) {
    return va >= TEXT_START_VA && va < TEXT_START_VA + TEXT_SIZE;
}

static BOOL IsVaInData(DWORD va) {
    return va >= DATA_START_VA && va < DATA_START_VA + DATA_SIZE;
}

static BOOL VerifyExeSize(void) {
    char path[MAX_PATH];
    HANDLE h;
    DWORD size;

    GetModuleFileNameA(NULL, path, MAX_PATH);
    h = CreateFileA(path, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
    if (h == INVALID_HANDLE_VALUE) return FALSE;
    size = GetFileSize(h, NULL);
    CloseHandle(h);
    return (size == EXPECTED_EXE_SIZE);
}

static void BuildOutputDir(void) {
    char dir[MAX_PATH];
    GetModuleFileNameA(g_hModule, dir, MAX_PATH);
    {
        char* slash = strrchr(dir, '\\');
        if (!slash) slash = strrchr(dir, '/');
        if (slash) *(slash + 1) = '\0';
        else dir[0] = '\0';
    }
    wsprintfA(g_outDir, "%sprobe_results\\", dir);
    CreateDirectoryA(g_outDir, NULL);
}

static void AppendFloat(char* buf, int buf_max, int* pos, float v) {
    int whole;
    int frac;
    int neg = 0;
    if (*pos >= buf_max - 32) return;
    if (v < 0.f) { neg = 1; v = -v; }
    whole = (int)v;
    frac = (int)((v - (float)whole) * 1000000.f);
    if (frac < 0) frac = 0;
    *pos += wsprintfA(buf + *pos, neg ? "-%d.%06d" : "%d.%06d", whole, frac);
}

static void JsonEscape(const char* in, char* out, int out_max) {
    int i = 0;
    int o = 0;
    if (!in) {
        out[0] = '\0';
        return;
    }
    while (in[i] && o < out_max - 8) {
        char c = in[i++];
        if (c == '"' || c == '\\') {
            out[o++] = '\\';
            out[o++] = c;
        } else if (c == '\r' || c == '\n' || c == '\t') {
            out[o++] = ' ';
        } else {
            out[o++] = c;
        }
    }
    out[o] = '\0';
}

static HANDLE OpenProbeFile(const char* name) {
    char path[MAX_PATH];
    wsprintfA(path, "%s%s", g_outDir, name);
    return CreateFileA(path, GENERIC_WRITE, FILE_SHARE_READ,
                      NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
}

static void WriteProbeStr(HANDLE hf, const char* s) {
    DWORD w;
    if (hf != INVALID_HANDLE_VALUE && s) {
        WriteFile(hf, s, (DWORD)strlen(s), &w, NULL);
    }
}

static void WriteProbeFmt(HANDLE hf, const char* fmt, ...) {
    char buf[2048];
    va_list ap;
    va_start(ap, fmt);
    wvsprintfA(buf, fmt, ap);
    va_end(ap);
    WriteProbeStr(hf, buf);
}

/* --- Spawn validation (must match pmc_blackbox) --- */

static void FixSpawnValidation(void) {
    BYTE* flag = (BYTE*)SPAWN_VALIDATION_FLAG_VA;
    DWORD old_prot;
    if (VirtualProtect(flag, 1, PAGE_READWRITE, &old_prot)) {
        *flag = 0x01;
        VirtualProtect(flag, 1, old_prot, &old_prot);
        Log("Spawn validation flag set (0x%08X = 0x01)", SPAWN_VALIDATION_FLAG_VA);
    }
}

/* --- Rdata / hook helpers --- */

static DWORD FindStringInRdata(const char* target) {
    BYTE* base = (BYTE*)RDATA_START_VA;
    size_t len = strlen(target);
    DWORD i;

    if (len == 0 || len >= RDATA_SIZE) return 0;
    for (i = 0; i + len < RDATA_SIZE; i++) {
        if (memcmp(base + i, target, len + 1) == 0) {
            return RDATA_START_VA + i;
        }
    }
    return 0;
}

static lua_CFunction FindLuaFuncForString(DWORD string_va) {
    BYTE* base = (BYTE*)RDATA_START_VA;
    DWORD i;

    for (i = 0; i + 8 < RDATA_SIZE; i += 4) {
        if (*(DWORD*)(base + i) == string_va) {
            DWORD func_va = *(DWORD*)(base + i + 4);
            if (IsVaInText(func_va)) {
                return (lua_CFunction)func_va;
            }
        }
    }
    return NULL;
}

static BOOL PatchRegFuncPointer(DWORD string_va, lua_CFunction new_func, lua_CFunction* out_orig) {
    BYTE* rdata = (BYTE*)RDATA_START_VA;
    DWORD i;

    for (i = 0; i + 8 < RDATA_SIZE; i += 4) {
        if (*(DWORD*)(rdata + i) == string_va) {
            DWORD* slot = (DWORD*)(rdata + i + 4);
            DWORD func_va = *slot;
            if (!IsVaInText(func_va)) continue;
            {
                DWORD old_prot;
                if (!VirtualProtect(slot, 4, PAGE_READWRITE, &old_prot)) {
                    return FALSE;
                }
                if (out_orig) *out_orig = (lua_CFunction)*slot;
                if (g_regRestoreCount < (int)(sizeof(g_regRestore) / sizeof(g_regRestore[0]))) {
                    g_regRestore[g_regRestoreCount].slot = slot;
                    g_regRestore[g_regRestoreCount].orig_func = *slot;
                    g_regRestoreCount++;
                }
                *slot = (DWORD)new_func;
                VirtualProtect(slot, 4, old_prot, &old_prot);
                return TRUE;
            }
        }
    }
    return FALSE;
}

static void RestoreAllRegPatches(void) {
    int i;
    for (i = 0; i < g_regRestoreCount; i++) {
        DWORD* slot = g_regRestore[i].slot;
        DWORD old_prot;
        if (!slot) continue;
        if (VirtualProtect(slot, 4, PAGE_READWRITE, &old_prot)) {
            *slot = g_regRestore[i].orig_func;
            VirtualProtect(slot, 4, old_prot, &old_prot);
        }
    }
    if (g_regRestoreCount > 0) {
        Log("Restored %d luaL_Reg capture hook(s)", g_regRestoreCount);
    }
    g_regRestoreCount = 0;
}

static DWORD FindFunctionStart(DWORD code_va) {
    BYTE* p;
    int back;

    if (!IsVaInText(code_va)) return 0;
    p = (BYTE*)code_va;
    for (back = 0; back < 0x600; back++) {
        BYTE* q = p - back;
        if (!IsVaInText((DWORD)q)) break;
        if (q[0] == 0x55 && q[1] == 0x8B && (q[2] == 0xEC || q[2] == 0xE9)) {
            return (DWORD)q;
        }
        if (q[0] == 0x53 && q[1] == 0x8B && q[2] == 0xDC) {
            return (DWORD)q;
        }
    }
    return code_va;
}

static DWORD FindCodeXrefToVa(DWORD target_va) {
    BYTE* text = (BYTE*)TEXT_START_VA;
    BYTE pat[4];
    DWORD i;

    pat[0] = (BYTE)(target_va);
    pat[1] = (BYTE)(target_va >> 8);
    pat[2] = (BYTE)(target_va >> 16);
    pat[3] = (BYTE)(target_va >> 24);
    for (i = 0; i + 4 < TEXT_SIZE; i++) {
        if (memcmp(text + i, pat, 4) == 0) {
            return TEXT_START_VA + i;
        }
    }
    return 0;
}

static DWORD ResolveFuncFromErrorString(const char* err) {
    DWORD str_va = FindStringInRdata(err);
    DWORD xref;
    if (!str_va) return 0;
    xref = FindCodeXrefToVa(str_va);
    if (!xref) return 0;
    return FindFunctionStart(xref);
}

static DWORD ResolveNearCallTarget(DWORD func_va, int call_index) {
    BYTE* p = (BYTE*)func_va;
    int found = 0;
    DWORD i;

    if (!IsVaInText(func_va)) return 0;
    for (i = 0; i + 5 < 0x300; i++) {
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
    DWORD next_fn, getfield, type_fn;
    int resolved = 0;

    memset(&g_api, 0, sizeof(g_api));
    next_fn = ResolveFuncFromErrorString("invalid key to 'next'");
    if (!next_fn) next_fn = ResolveFuncFromErrorString("table overflow");
    getfield = ResolveFuncFromErrorString("value expected");
    type_fn = ResolveFuncFromErrorString("no value");

    if (next_fn) { g_api.next_fn = (pfn_lua_next)next_fn; resolved++; }
    if (getfield) {
        /* lua_getfield often near globalsindex immediate */
        BYTE* text = (BYTE*)TEXT_START_VA;
        DWORD i;
        for (i = 0; i + 5 < TEXT_SIZE; i++) {
            if (text[i] == 0xB9 && *(DWORD*)(text + i + 1) == (DWORD)LUA_GLOBALSINDEX) {
                DWORD f = FindFunctionStart(TEXT_START_VA + i);
                if (f) { g_api.getfield = (pfn_lua_getfield)f; resolved++; break; }
            }
        }
    }
    if (type_fn) { g_api.type_fn = (pfn_lua_type)type_fn; resolved++; }

    if (next_fn) {
        DWORD pushnil_cand = ResolveNearCallTarget(next_fn - 0x200, 0);
        if (pushnil_cand) { g_api.pushnil = (pfn_lua_pushnil)pushnil_cand; resolved++; }
    }
    if (g_api.getfield) {
        DWORD settop_cand = FindFunctionStart((DWORD)g_api.getfield - 0x80);
        if (settop_cand) {
            g_api.settop = (pfn_lua_settop)settop_cand;
            g_api.gettop = (pfn_lua_gettop)(settop_cand - 0x30);
            resolved++;
        }
    }
    {
        DWORD tol = ResolveFuncFromErrorString("string expected");
        if (tol) { g_api.tolstring = (pfn_lua_tolstring)tol; resolved++; }
    }
    if (type_fn) {
        DWORD toc = FindFunctionStart(type_fn + 0x40);
        if (toc) { g_api.tocfunction = (pfn_lua_tocfunction)toc; resolved++; }
    }

    Log("Lua API resolved: %d symbols", resolved);
    return g_api.next_fn && g_api.pushnil && g_api.settop && g_api.type_fn;
}

/* --- lua_State capture --- */

static int Hook_CaptureLua(lua_State* L) {
    if (!L) return 0;
    if (InterlockedCompareExchange(&g_luaCaptured, 1, 0) == 0) {
        g_L = L;
        Log("Captured lua_State* = 0x%08X (game thread)", (DWORD)L);
        /* Restore reg table immediately — persistent patches break net/Lua and
         * conflict with dlc_enable.asi inline hooks on the same functions. */
        RestoreAllRegPatches();
    }
    return 0;
}

static int Hook_CaptureIsDemoMode(lua_State* L) {
    Hook_CaptureLua(L);
    if (g_origIsDemoMode) return g_origIsDemoMode(L);
    return 0;
}

static int Hook_CaptureGetLanguage(lua_State* L) {
    Hook_CaptureLua(L);
    if (g_origGetLanguage) return g_origGetLanguage(L);
    return 0;
}

static int Hook_CaptureIsOnlineConnected(lua_State* L) {
    Hook_CaptureLua(L);
    if (g_origIsOnlineConnected) return g_origIsOnlineConnected(L);
    return 0;
}

static void InstallCaptureHooks(void) {
    DWORD str_demo, str_lang, str_online;

    if (InterlockedCompareExchange(&g_captureInstalled, 1, 0) != 0) return;

    str_online = FindStringInRdata("IsOnlineConnected");
    if (str_online) {
        g_origIsOnlineConnected = FindLuaFuncForString(str_online);
        if (g_origIsOnlineConnected && PatchRegFuncPointer(str_online, Hook_CaptureIsOnlineConnected, NULL)) {
            Log("Capture hook: IsOnlineConnected (orig=0x%08X)", (DWORD)g_origIsOnlineConnected);
        }
    }

    str_demo = FindStringInRdata("IsDemoMode");
    if (str_demo) {
        g_origIsDemoMode = FindLuaFuncForString(str_demo);
        if (g_origIsDemoMode && PatchRegFuncPointer(str_demo, Hook_CaptureIsDemoMode, NULL)) {
            Log("Capture hook: IsDemoMode (orig=0x%08X)", (DWORD)g_origIsDemoMode);
        }
    }

    str_lang = FindStringInRdata("GetLanguage");
    if (str_lang) {
        g_origGetLanguage = FindLuaFuncForString(str_lang);
        if (g_origGetLanguage && PatchRegFuncPointer(str_lang, Hook_CaptureGetLanguage, NULL)) {
            Log("Capture hook: GetLanguage (orig=0x%08X)", (DWORD)g_origGetLanguage);
        }
    }
}

/* --- Hex dump helper --- */

static void BytesToHex(const BYTE* data, int len, char* out, int out_max) {
    int i;
    int pos = 0;
    for (i = 0; i < len && pos < out_max - 4; i++) {
        if (i > 0 && (i % 16) == 0 && pos < out_max - 3) {
            out[pos++] = ' ';
        }
        pos += wsprintfA(out + pos, "%02X", data[i]);
    }
    out[pos] = '\0';
}

/* --- Probe 1: lua_state_layout --- */

static void ProbeLuaStateLayout(void) {
    HANDLE hf;
    BYTE* Lp;
    DWORD off;
    SYSTEMTIME st;

    hf = OpenProbeFile("lua_state_layout.json");
    if (hf == INVALID_HANDLE_VALUE) {
        Log("ERROR: cannot write lua_state_layout.json");
        return;
    }

    GetLocalTime(&st);
    WriteProbeFmt(hf,
        "{\r\n"
        "  \"generator\": \"mercs2_probe.asi\",\r\n"
        "  \"probe\": \"lua_state_layout\",\r\n"
        "  \"timestamp\": \"%04u-%02u-%02uT%02u:%02u:%02u\",\r\n"
        "  \"exe_verified\": %s,\r\n"
        "  \"lua_state_va\": \"0x%08X\",\r\n",
        (unsigned)st.wYear, (unsigned)st.wMonth, (unsigned)st.wDay,
        (unsigned)st.wHour, (unsigned)st.wMinute, (unsigned)st.wSecond,
        g_exeVerified ? "true" : "false",
        (DWORD)g_L);

    WriteProbeStr(hf,
        "  \"documented_offsets\": {\r\n"
        "    \"top\": 8,\r\n"
        "    \"base\": 12,\r\n"
        "    \"l_G\": 16,\r\n"
        "    \"ci\": 20,\r\n"
        "    \"stack_last\": 28,\r\n"
        "    \"stack\": 32,\r\n"
        "    \"TValue_size\": 8,\r\n"
        "    \"TString_data_offset\": 16\r\n"
        "  },\r\n");

    if (!g_L || !PtrReadable(g_L, 0x80)) {
        WriteProbeStr(hf, "  \"error\": \"lua_State not captured or unreadable\",\r\n");
        WriteProbeStr(hf, "  \"fields\": []\r\n}\r\n");
        CloseHandle(hf);
        return;
    }

    Lp = (BYTE*)g_L;
    WriteProbeStr(hf, "  \"fields\": [\r\n");

    for (off = 0; off <= 0x60; off += 4) {
        DWORD val = 0;
        const char* note = "";
        BOOL readable = PtrReadable(Lp + off, 4);

        if (readable) val = *(DWORD*)(Lp + off);

        if (off == OFF_L_TOP) note = "top (documented)";
        else if (off == OFF_L_BASE) note = "base (documented)";
        else if (off == OFF_L_L_G) note = "l_G (documented)";
        else if (off == OFF_L_CI) note = "ci (documented)";
        else if (off == OFF_L_STACK_LAST) note = "stack_last (documented)";
        else if (off == OFF_L_STACK) note = "stack (documented)";

        WriteProbeFmt(hf,
            "    {\"offset\": %u, \"u32\": \"0x%08X\", \"readable\": %s, \"note\": \"%s\"}%s\r\n",
            off, val, readable ? "true" : "false", note,
            (off < 0x60) ? "," : "");

    }

    /* TValue stride from stack */
    {
        DWORD stack = 0, top = 0, stride = 0;
        if (PtrReadable(Lp + OFF_L_STACK, 4)) stack = *(DWORD*)(Lp + OFF_L_STACK);
        if (PtrReadable(Lp + OFF_L_TOP, 4)) top = *(DWORD*)(Lp + OFF_L_TOP);
        if (stack && top > stack && (top - stack) % 8 == 0) {
            stride = 8;
        }
        WriteProbeFmt(hf,
            "  ],\r\n"
            "  \"tvalue_stride_bytes\": %u,\r\n",
            stride);
    }

    /* TString probe: find a string on stack */
    WriteProbeStr(hf, "  \"tstring_probes\": [\r\n");
    {
        LuaTValue* stack;
        LuaTValue* top;
        int found = 0;
        int first = 1;

        if (PtrReadable(Lp + OFF_L_STACK, 8) && PtrReadable(Lp + OFF_L_TOP, 4)) {
            stack = *(LuaTValue**)(Lp + OFF_L_STACK);
            top = *(LuaTValue**)(Lp + OFF_L_TOP);
            if (stack && top && top > stack && PtrReadable(stack, (SIZE_T)((top - stack) * sizeof(LuaTValue)))) {
                LuaTValue* p;
                for (p = stack; p < top && found < 8; p++) {
                    if (p->tt == LUA_TSTRING && p->value) {
                        int off_try;
                        for (off_try = 8; off_try <= 24; off_try += 4) {
                            const char* s = (const char*)((BYTE*)p->value + off_try);
                            if (PtrReadable(s, 4) && s[0] >= 0x20 && s[0] < 0x7f) {
                                char esc[128];
                                JsonEscape(s, esc, sizeof(esc));
                                WriteProbeFmt(hf,
                                    "%s    {\"tstring_ptr\": \"0x%08X\", \"data_offset\": %d, \"preview\": \"%s\"}\r\n",
                                    first ? "" : ",",
                                    p->value, off_try, esc);
                                first = 0;
                                found++;
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
    WriteProbeStr(hf, "  ],\r\n");

    /* global_State peek */
    WriteProbeStr(hf, "  \"global_state_fields\": [\r\n");
    {
        DWORD l_G = 0;
        int first = 1;
        if (PtrReadable(Lp + OFF_L_L_G, 4)) {
            l_G = *(DWORD*)(Lp + OFF_L_L_G);
            if (l_G && PtrReadable((void*)l_G, 0x40)) {
                for (off = 0; off < 0x40; off += 4) {
                    DWORD val = *(DWORD*)((BYTE*)l_G + off);
                    WriteProbeFmt(hf,
                        "%s    {\"offset\": %u, \"u32\": \"0x%08X\"}\r\n",
                        first ? "" : ",", off, val);
                    first = 0;
                }
            }
        }
        if (first) WriteProbeStr(hf, "    {\"note\": \"l_G unreadable\"}\r\n");
    }
    WriteProbeStr(hf, "  ]\r\n}\r\n");

    CloseHandle(hf);
    Log("Wrote lua_state_layout.json");
}

/* --- Probe 2: lua_api_signatures --- */

typedef struct {
    const char* name;
    DWORD va;
} ApiTarget;

static void DumpCallersForVa(HANDLE hf, DWORD target_va) {
    BYTE* text = (BYTE*)TEXT_START_VA;
    DWORD i;
    int count = 0;
    int first = 1;

    WriteProbeStr(hf, "      \"call_sites\": [\r\n");
    for (i = 0; i + 5 < TEXT_SIZE && count < PROBE_MAX_CALLERS; i++) {
        if (text[i] == 0xE8) {
            int rel = *(int*)(text + i + 1);
            DWORD site = TEXT_START_VA + i;
            DWORD dst = site + 5 + rel;
            if (dst == target_va) {
                BYTE pre[24];
                char hex[128];
                DWORD start = (site > 24) ? site - 24 : TEXT_START_VA;
                int pre_len = (int)(site - start);

                memset(pre, 0, sizeof(pre));
                if (PtrReadable((void*)start, pre_len) && pre_len <= 24) {
                    memcpy(pre, (void*)start, pre_len);
                }
                BytesToHex(pre, pre_len > 24 ? 24 : pre_len, hex, sizeof(hex));
                WriteProbeFmt(hf,
                    "%s        {\"site_va\": \"0x%08X\", \"bytes_before_call\": \"%s\"}\r\n",
                    first ? "" : ",", site, hex);
                first = 0;
                count++;
            }
        }
    }
    WriteProbeStr(hf, "      ]\r\n");
}

static void ProbeLuaApiSignatures(void) {
    HANDLE hf;
    static const ApiTarget targets[] = {
        { "luaL_loadbuffer", VA_LUAL_LOADBUFFER },
        { "lua_pcall", VA_LUA_PCALL },
        { "luaL_typerror", VA_LUAL_TYPERROR },
        { "luaD_pcall", VA_LUAD_PCALL },
        { "luaB_loadstring", VA_LUAB_LOADSTRING },
        { "luaB_pcall", VA_LUAB_PCALL },
        { "print_stub", VA_PRINT_STUB },
        { NULL, 0 }
    };
    int ti;

    hf = OpenProbeFile("lua_api_signatures.json");
    if (hf == INVALID_HANDLE_VALUE) return;

    WriteProbeStr(hf,
        "{\r\n"
        "  \"generator\": \"mercs2_probe.asi\",\r\n"
        "  \"probe\": \"lua_api_signatures\",\r\n"
        "  \"documented_ltcg\": {\r\n"
        "    \"luaL_loadbuffer\": \"EAX=name, EDX=L, stack=buff,sz\",\r\n"
        "    \"lua_pcall\": \"EAX=L, ECX=errfunc, EDI=nresults, stack=nargs\"\r\n"
        "  },\r\n"
        "  \"functions\": [\r\n");

    for (ti = 0; targets[ti].name; ti++) {
        BYTE prologue[64];
        char hex[256];
        DWORD va = targets[ti].va;
        int len = 64;

        memset(prologue, 0, sizeof(prologue));
        if (IsVaInText(va) && PtrReadable((void*)va, len)) {
            memcpy(prologue, (void*)va, len);
        }
        BytesToHex(prologue, len, hex, sizeof(hex));

        WriteProbeFmt(hf,
            "    {\r\n"
            "      \"name\": \"%s\",\r\n"
            "      \"va\": \"0x%08X\",\r\n"
            "      \"prologue_hex\": \"%s\",\r\n",
            targets[ti].name, va, hex);
        DumpCallersForVa(hf, va);
        WriteProbeFmt(hf, "    }%s\r\n", targets[ti + 1].name ? "," : "");
    }

    WriteProbeStr(hf, "  ]\r\n}\r\n");
    CloseHandle(hf);
    Log("Wrote lua_api_signatures.json");
}

/* --- Binding helpers for probe 3 --- */

static BOOL PathExists(const char* path) {
    int i;
    for (i = 0; i < g_bindingCount; i++) {
        if (strcmp(g_bindings[i].path, path) == 0) return TRUE;
    }
    return FALSE;
}

static BOOL IsIdentChar(char c) {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
           (c >= '0' && c <= '9') || c == '_';
}

static BOOL IsValidBindingName(const char* s) {
    size_t len;
    size_t i;
    if (!s || !PtrReadable(s, 1)) return FALSE;
    len = strlen(s);
    if (len == 0 || len > 96) return FALSE;
    if (!IsIdentChar(s[0]) && s[0] != '_') return FALSE;
    for (i = 0; i < len; i++) {
        if (!IsIdentChar(s[i])) return FALSE;
    }
    return TRUE;
}

static int HeuristicArgRetCount(DWORD func_va) {
    BYTE* p;
    DWORD i;
    int ret_count = 0;
    int has_gettop = 0;

    if (!IsVaInText(func_va)) return 0;
    p = (BYTE*)func_va;
    for (i = 0; i + 3 < 128; i++) {
        if (p[i] == 0xC2 || p[i] == 0xC3) {
            if (p[i] == 0xC2 && i + 2 < 128) {
                ret_count = p[i + 1] | (p[i + 2] << 8);
            } else {
                ret_count = 1;
            }
            break;
        }
        if (p[i] == 0xE8) has_gettop = 1;
    }
    (void)has_gettop;
    return ret_count;
}

static BOOL AddBinding(const char* path, const char* type_name, int lua_type,
                       DWORD func_va, int depth, int source) {
    BindingEntry* e;
    if (g_bindingCount >= PROBE_MAX_BINDINGS) return FALSE;
    if (PathExists(path)) return TRUE;
    e = &g_bindings[g_bindingCount++];
    strncpy(e->path, path, PROBE_MAX_PATH - 1);
    e->path[PROBE_MAX_PATH - 1] = '\0';
    strncpy(e->type_name, type_name, sizeof(e->type_name) - 1);
    e->lua_type = lua_type;
    e->func_va = func_va;
    e->depth = depth;
    e->source = source;
    e->arg_heuristic = (func_va && lua_type == LUA_TFUNCTION) ? -1 : 0;
    e->ret_heuristic = (func_va && lua_type == LUA_TFUNCTION) ? HeuristicArgRetCount(func_va) : 0;
    return TRUE;
}

static BOOL IsVisitedTable(DWORD t) {
    int i;
    for (i = 0; i < g_visitedCount; i++) {
        if (g_visited[i] == t) return TRUE;
    }
    return FALSE;
}

static void MarkVisited(DWORD t) {
    if (g_visitedCount < PROBE_MAX_VISITED && !IsVisitedTable(t)) {
        g_visited[g_visitedCount++] = t;
    }
}

static BOOL IsValidRegPair(DWORD name_va, DWORD func_va) {
    const char* name;
    if (!IsVaInRdata(name_va) || !IsVaInText(func_va)) return FALSE;
    name = (const char*)name_va;
    return IsValidBindingName(name);
}

static const char* LookupVerifiedNamespace(DWORD table_va) {
    int i;
    for (i = 0; i < (int)(sizeof(VERIFIED_REG_TABLES) / sizeof(VERIFIED_REG_TABLES[0])); i++) {
        if (VERIFIED_REG_TABLES[i].table_va == table_va) {
            return VERIFIED_REG_TABLES[i].namespace;
        }
    }
    return NULL;
}

static void ScanRegTableAt(DWORD table_va, const char* namespace) {
    BYTE* p = (BYTE*)table_va;
    DWORD end = table_va + 0x2000;
    int consecutive = 0;
    char table_label[64];

    if (namespace && namespace[0]) {
        strncpy(table_label, namespace, sizeof(table_label) - 1);
        table_label[sizeof(table_label) - 1] = '\0';
    } else {
        wsprintfA(table_label, "table@0x%08X", table_va);
    }

    while ((DWORD)p + 8 <= end) {
        DWORD name_va = *(DWORD*)p;
        DWORD func_va = *(DWORD*)(p + 4);
        const char* name;
        char path[PROBE_MAX_PATH];

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
        wsprintfA(path, "%s.%s", table_label, name);
        AddBinding(path, "function", LUA_TFUNCTION, func_va, 0, 1);
        p += 8;
    }
}

static DWORD SkipRegTableGap(DWORD foff, DWORD limit) {
    while (foff < limit) {
        DWORD name_va = *(DWORD*)foff;
        DWORD func_va = *(DWORD*)(foff + 4);
        if (name_va == 0 && func_va == 0) {
            return foff + 4;
        }
        if (IsValidRegPair(name_va, func_va)) {
            return foff;
        }
        foff += 4;
    }
    return foff;
}

static DWORD ParseRegTableEnd(DWORD table_va) {
    DWORD va = table_va;
    DWORD limit = table_va + 0x4000;
    int entries = 0;

    while (va + 8 <= limit) {
        DWORD name_va = *(DWORD*)va;
        DWORD func_va = *(DWORD*)(va + 4);
        if (name_va == 0 && func_va == 0) {
            return va + 8;
        }
        if (!IsValidRegPair(name_va, func_va)) {
            break;
        }
        entries++;
        va += 8;
    }
    return (entries >= 2) ? va : 0;
}

static void ScanPrimaryCluster(void) {
    DWORD va = REG_TABLE_START_VA;
    DWORD end = REG_TABLE_SCAN_END_VA;
    int tables = 0;
    int before = g_bindingCount;

    while (va < end) {
        DWORD table_end = ParseRegTableEnd(va);
        const char* ns;

        if (!table_end) {
            va += 4;
            continue;
        }
        ns = LookupVerifiedNamespace(va);
        ScanRegTableAt(va, ns);
        tables++;
        va = SkipRegTableGap(table_end, end);
    }
    Log("Primary cluster scan: %d tables, +%d bindings (verified ns only when mapped)",
        tables, g_bindingCount - before);
}

static void WalkTable(lua_State* L, int tbl_idx, const char* prefix, int depth) {
    const char* key;
    int t_key, t_val;

    if (!g_api.next_fn || !g_api.pushnil || !g_api.settop || !g_api.type_fn) return;
    if (depth >= PROBE_MAX_DEPTH) return;

    if (tbl_idx < 0) {
        g_api.pushnil(L);
        tbl_idx--;
    } else {
        g_api.pushnil(L);
    }

    while (g_api.next_fn(L, tbl_idx)) {
        t_key = g_api.type_fn(L, -2);
        t_val = g_api.type_fn(L, -1);
        if (t_key == LUA_TSTRING && g_api.tolstring) {
            key = g_api.tolstring(L, -2, NULL);
            if (key && IsValidBindingName(key)) {
                char path[PROBE_MAX_PATH];
                DWORD fva = 0;
                if (prefix[0]) wsprintfA(path, "%s.%s", prefix, key);
                else strncpy(path, key, sizeof(path) - 1);
                if (t_val == LUA_TFUNCTION && g_api.tocfunction) {
                    lua_CFunction fn = g_api.tocfunction(L, -1);
                    if (fn) fva = (DWORD)fn;
                }
                AddBinding(path, "function", t_val, fva, depth, 0);
                if (t_val == LUA_TTABLE) WalkTable(L, -1, path, depth + 1);
            }
        }
        g_api.settop(L, -1);
    }
    if (g_api.gettop) g_api.settop(L, g_api.gettop(L) - 2);
    else g_api.settop(L, -3);
}

static void EnumerateGlobalsRuntime(lua_State* L) {
    const char* key;
    int t_key, t_val;

    if (!g_api.next_fn) return;
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
                AddBinding(key, "table", t_val, fva, 0, 0);
                if (t_val == LUA_TTABLE) WalkTable(L, -1, key, 1);
            }
        }
        g_api.settop(L, -1);
    }
}

static void ProbeLuaBindingDeepScan(void) {
    HANDLE hf;
    int i;
    BOOL runtime_ok = FALSE;
    char esc[PROBE_MAX_PATH + 32];

    g_bindingCount = 0;

#if MERCS2_PROBE_RUNTIME_WALK
    if (g_L && ResolveLuaAPI()) {
        Log("WARNING: runtime _G walk on worker thread — unsafe");
        EnumerateGlobalsRuntime(g_L);
        runtime_ok = TRUE;
    }
#else
    if (g_L) {
        Log("runtime _G walk skipped (MERCS2_PROBE_RUNTIME_WALK=0; Lua not thread-safe)");
    }
#endif

    ScanPrimaryCluster();

    hf = OpenProbeFile("lua_bindings_deep.json");
    if (hf == INVALID_HANDLE_VALUE) return;

    WriteProbeFmt(hf,
        "{\r\n"
        "  \"generator\": \"mercs2_probe.asi\",\r\n"
        "  \"probe\": \"lua_binding_deep_scan\",\r\n"
        "  \"lua_state\": \"0x%08X\",\r\n"
        "  \"runtime_walk\": %s,\r\n"
        "  \"binding_count\": %d,\r\n"
        "  \"bindings\": [\r\n",
        (DWORD)g_L, runtime_ok ? "true" : "false", g_bindingCount);

    for (i = 0; i < g_bindingCount; i++) {
        BindingEntry* e = &g_bindings[i];
        JsonEscape(e->path, esc, sizeof(esc));
        WriteProbeFmt(hf,
            "    {\"path\": \"%s\", \"type\": \"%s\", \"lua_type\": %d,"
            " \"func_va\": \"0x%08X\", \"depth\": %d, \"source\": \"%s\","
            " \"ret_heuristic\": %d, \"arg_heuristic\": %d}%s\r\n",
            esc, e->type_name, e->lua_type, e->func_va, e->depth,
            e->source ? "static" : "runtime",
            e->ret_heuristic, e->arg_heuristic,
            (i + 1 < g_bindingCount) ? "," : "");
    }

    WriteProbeStr(hf, "  ]\r\n}\r\n");
    CloseHandle(hf);
    Log("Wrote lua_bindings_deep.json (%d bindings)", g_bindingCount);
}

/* --- Probe 4: game_object_probe --- */

static void SampleUserdata(DWORD ud_ptr) {
    ObjectSample* s;
    int off;

    if (!ud_ptr || g_objectSampleCount >= PROBE_MAX_OBJECT_SAMPLES) return;
    if (!PtrReadable((void*)ud_ptr, 256)) return;

    s = &g_objectSamples[g_objectSampleCount++];
    s->userdata_ptr = ud_ptr;
    s->sample_count = 0;

    for (off = 0; off < 256 && s->sample_count < 64; off += 4) {
        if (PtrReadable((void*)(ud_ptr + off), 4)) {
            s->dword_offsets[s->sample_count] = (DWORD)off;
            s->dword_values[s->sample_count] = *(DWORD*)(ud_ptr + off);
            s->sample_count++;
        }
    }
}

static BOOL ResolvePrintStack(lua_State* L, LuaTValue** out_base, int* out_nargs) {
    BYTE* Lp = (BYTE*)L;
    LuaTValue* top;
    LuaTValue* base;
    LuaTValue* stack;
    LuaTValue* stack_last;
    int nargs;

    if (!PtrReadable(Lp + OFF_L_STACK, 12)) return FALSE;
    top = *(LuaTValue**)(Lp + OFF_L_TOP);
    base = *(LuaTValue**)(Lp + OFF_L_BASE);
    stack = *(LuaTValue**)(Lp + OFF_L_STACK);
    stack_last = *(LuaTValue**)(Lp + OFF_L_STACK_LAST);
    if (!stack || !top || !stack_last) return FALSE;
    if (base < stack || base > stack_last || top < base) return FALSE;
    nargs = (int)(top - base);
    if (nargs <= 0 || nargs > 32) return FALSE;
    *out_base = base;
    *out_nargs = nargs;
    return TRUE;
}

static int Hook_ProbeGetPosition(lua_State* L) {
    LuaTValue* base;
    int nargs = 0;
    int i;

    Hook_CaptureLua(L);

    if (InterlockedCompareExchange(&g_objectHookFired, 1, 0) == 0) {
        if (ResolvePrintStack(L, &base, &nargs)) {
            for (i = 0; i < nargs; i++) {
                if (base[i].tt == LUA_TUSERDATA || base[i].tt == LUA_TLIGHTUSERDATA) {
                    SampleUserdata(base[i].value);
                }
            }
        }
        Log("Object.GetPosition probe: sampled stack (nargs=%d)", nargs);
    }

    if (g_origGetPosition) return g_origGetPosition(L);
    return 0;
}

static lua_CFunction FindBindingInNamespace(const char* ns, const char* method) {
    DWORD ns_va = FindStringInRdata(ns);
    DWORD method_va;
    BYTE* rdata;
    DWORD i;

    if (!ns_va) return NULL;
    method_va = FindStringInRdata(method);
    if (!method_va) return NULL;

    rdata = (BYTE*)RDATA_START_VA;
    for (i = 0; i + 8 < RDATA_SIZE; i += 4) {
        if (*(DWORD*)(rdata + i) == method_va) {
            DWORD func_va = *(DWORD*)(rdata + i + 4);
            if (IsVaInText(func_va)) {
                return (lua_CFunction)func_va;
            }
        }
    }
    (void)ns_va;
    return NULL;
}

static void InstallObjectProbeHook(void) {
    lua_CFunction fn = FindBindingInNamespace("Object", "GetPosition");
    DWORD str_gp;

    if (!fn) {
        str_gp = FindStringInRdata("GetPosition");
        if (str_gp) fn = FindLuaFuncForString(str_gp);
    }
    if (!fn) {
        Log("Object.GetPosition not found — skip object hook");
        return;
    }
    g_origGetPosition = fn;
    str_gp = FindStringInRdata("GetPosition");
    if (str_gp && PatchRegFuncPointer(str_gp, Hook_ProbeGetPosition, &g_origGetPosition)) {
        Log("Object probe hook on GetPosition (orig=0x%08X)", (DWORD)g_origGetPosition);
    } else {
        Log("WARNING: GetPosition patch failed (multiple tables?) orig=0x%08X", (DWORD)fn);
    }
}

static void ProbeGameObjects(void) {
    HANDLE hf;
    int si;
    int di;
    SYSTEMTIME st;

    hf = OpenProbeFile("game_objects.json");
    if (hf == INVALID_HANDLE_VALUE) return;

    GetLocalTime(&st);
    WriteProbeFmt(hf,
        "{\r\n"
        "  \"generator\": \"mercs2_probe.asi\",\r\n"
        "  \"probe\": \"game_object_probe\",\r\n"
        "  \"timestamp\": \"%04u-%02u-%02uT%02u:%02u:%02u\",\r\n"
        "  \"placement_record_bytes\": 42,\r\n"
        "  \"documented_placement_offsets\": {\r\n"
        "    \"x\": 0, \"y\": 4, \"z\": 8,\r\n"
        "    \"qx\": 20, \"qy\": 24, \"qz\": 28, \"qw\": 32\r\n"
        "  },\r\n"
        "  \"object_hook_fired\": %s,\r\n"
        "  \"sample_count\": %d,\r\n"
        "  \"samples\": [\r\n",
        (unsigned)st.wYear, (unsigned)st.wMonth, (unsigned)st.wDay,
        (unsigned)st.wHour, (unsigned)st.wMinute, (unsigned)st.wSecond,
        g_objectHookFired ? "true" : "false",
        g_objectSampleCount);

    for (si = 0; si < g_objectSampleCount; si++) {
        ObjectSample* s = &g_objectSamples[si];
        WriteProbeFmt(hf,
            "    {\r\n"
            "      \"userdata_ptr\": \"0x%08X\",\r\n"
            "      \"dwords\": [\r\n",
            s->userdata_ptr);
        for (di = 0; di < (int)s->sample_count; di++) {
            WriteProbeFmt(hf,
                "        {\"offset\": %u, \"value\": \"0x%08X\"}%s\r\n",
                s->dword_offsets[di], s->dword_values[di],
                (di + 1 < (int)s->sample_count) ? "," : "");
        }
        WriteProbeFmt(hf, "      ]\r\n    }%s\r\n", (si + 1 < g_objectSampleCount) ? "," : "");
    }

    /* Scan .data for pointer clusters that look like float triplets */
    WriteProbeStr(hf,
        "  ],\r\n"
        "  \"data_section_float_triplets\": [\r\n");
    {
        BYTE* data = (BYTE*)DATA_START_VA;
        DWORD i;
        int found = 0;
        int first = 1;
        for (i = 0; i + 12 < DATA_SIZE && found < 20; i += 4) {
            float x, y, z;
            if (!PtrReadable(data + i, 12)) continue;
            memcpy(&x, data + i, 4);
            memcpy(&y, data + i + 4, 4);
            memcpy(&z, data + i + 8, 4);
            if (x > -5000.f && x < 5000.f && y > -200.f && y < 500.f &&
                z > -5000.f && z < 5000.f &&
                (x != 0.f || y != 0.f || z != 0.f)) {
                char line[256];
                int pos = 0;
                line[0] = '\0';
                if (!first) {
                    WriteProbeStr(hf, ",");
                }
                pos += wsprintfA(line + pos, "    {\"data_va\": \"0x%08X\", \"x\": ", DATA_START_VA + i);
                AppendFloat(line, (int)sizeof(line), &pos, x);
                pos += wsprintfA(line + pos, ", \"y\": ");
                AppendFloat(line, (int)sizeof(line), &pos, y);
                pos += wsprintfA(line + pos, ", \"z\": ");
                AppendFloat(line, (int)sizeof(line), &pos, z);
                pos += wsprintfA(line + pos, "}\r\n");
                WriteProbeStr(hf, line);
                first = 0;
                found++;
                i += 8;
            }
        }
    }
    WriteProbeStr(hf, "  ]\r\n}\r\n");
    CloseHandle(hf);
    Log("Wrote game_objects.json");
}

/* --- Probe 5: memory_map --- */

static void ProbeMemoryMap(void) {
    HANDLE hf;
    HMODULE mods[256];
    DWORD needed;
    unsigned i;
    MODULEINFO mi;
    char mod_path[MAX_PATH];

    hf = OpenProbeFile("memory_map.json");
    if (hf == INVALID_HANDLE_VALUE) return;

    WriteProbeStr(hf,
        "{\r\n"
        "  \"generator\": \"mercs2_probe.asi\",\r\n"
        "  \"probe\": \"memory_map\",\r\n"
        "  \"exe_size_expected\": 53482288,\r\n"
        "  \"image_base\": \"0x00400000\",\r\n"
        "  \"sections_documented\": {\r\n"
        "    \".text\": {\"start\": \"0x00401000\", \"size\": \"0x00703000\"},\r\n"
        "    \".rdata\": {\"start\": \"0x00B05000\", \"size\": \"0x000F1000\"},\r\n"
        "    \".data\": {\"start\": \"0x00BF6000\", \"size\": \"0x00DA4000\"}\r\n"
        "  },\r\n"
        "  \"modules\": [\r\n");

    if (EnumProcessModules(GetCurrentProcess(), mods, sizeof(mods), &needed)) {
        unsigned count = needed / sizeof(HMODULE);
        for (i = 0; i < count; i++) {
            if (GetModuleInformation(GetCurrentProcess(), mods[i], &mi, sizeof(mi))) {
                mod_path[0] = '\0';
                char esc[MAX_PATH * 2];
                GetModuleFileNameA(mods[i], mod_path, MAX_PATH);
                JsonEscape(mod_path, esc, (int)sizeof(esc));
                WriteProbeFmt(hf,
                    "    {\"base\": \"0x%08X\", \"size\": %u, \"path\": \"%s\"}%s\r\n",
                    (DWORD)(ULONG_PTR)mi.lpBaseOfDll, (unsigned)mi.SizeOfImage, esc,
                    (i + 1 < count) ? "," : "");
            }
        }
    }

    WriteProbeStr(hf,
        "  ],\r\n"
        "  \"heap\": {\r\n");
    {
        HANDLE heaps[64];
        DWORD nheaps = GetProcessHeaps(64, heaps);
        unsigned h;
        WriteProbeFmt(hf, "    \"heap_count\": %u,\r\n", nheaps);
        WriteProbeStr(hf, "    \"entries\": [\r\n");
        for (h = 0; h < nheaps && h < 64; h++) {
            PROCESS_HEAP_ENTRY ent;
            DWORD total = 0;
            DWORD blocks = 0;
            memset(&ent, 0, sizeof(ent));
            while (HeapWalk(heaps[h], &ent)) {
                if (ent.wFlags & PROCESS_HEAP_ENTRY_BUSY) {
                    total += ent.cbData;
                    blocks++;
                }
            }
            WriteProbeFmt(hf,
                "      {\"index\": %u, \"busy_bytes\": %u, \"busy_blocks\": %u}%s\r\n",
                h, total, blocks, (h + 1 < nheaps && h + 1 < 64) ? "," : "");
        }
        WriteProbeStr(hf, "    ]\r\n");
    }
    WriteProbeStr(hf, "  }\r\n}\r\n");
    CloseHandle(hf);
    Log("Wrote memory_map.json");
}

/* --- Dispatcher --- */

static void WriteLuaStateLayoutSkipped(void) {
    HANDLE hf = OpenProbeFile("lua_state_layout.json");
    if (hf == INVALID_HANDLE_VALUE) return;
    WriteProbeStr(hf,
        "{\r\n"
        "  \"generator\": \"mercs2_probe.asi\",\r\n"
        "  \"probe\": \"lua_state_layout\",\r\n"
        "  \"error\": \"lua_State not captured — reach main menu or in-game before probe timeout\",\r\n"
        "  \"lua_state_va\": null,\r\n"
        "  \"fields\": []\r\n"
        "}\r\n");
    CloseHandle(hf);
    Log("Wrote lua_state_layout.json (skipped — no L)");
}

static void RunAllProbes(void) {
    Log("=== Running probe modules ===");
    ProbeMemoryMap();
    ProbeLuaApiSignatures();
    if (g_L) {
        ProbeLuaStateLayout();
    } else {
        WriteLuaStateLayoutSkipped();
    }
    ProbeLuaBindingDeepScan();
    ProbeGameObjects();
    Log("=== All probes complete — output in probe_results/ ===");
}

static DWORD WINAPI ProbeThread(LPVOID param) {
    DWORD wait_start;
    (void)param;

    Log("mercs2_probe.asi worker started (delay %u ms)", PROBE_DELAY_MS);
    BuildOutputDir();

    Sleep(2000);
    InstallCaptureHooks();
#if MERCS2_PROBE_OBJECT_HOOK
    InstallObjectProbeHook();
#else
    Log("Object.GetPosition hook disabled (MERCS2_PROBE_OBJECT_HOOK=0)");
#endif

    Sleep(PROBE_DELAY_MS > 2000 ? PROBE_DELAY_MS - 2000 : 1000);

    wait_start = GetTickCount();
    while (!g_luaCaptured && (GetTickCount() - wait_start) < (DWORD)PROBE_CAPTURE_WAIT_MS) {
        Sleep(100);
    }

    if (!g_L) {
        Log("WARNING: lua_State* not captured after %u ms — static probes only",
            PROBE_CAPTURE_WAIT_MS);
        Log("TIP: load to main menu or in-game; IsOnlineConnected fires early");
    } else {
        Log("lua_State* ready — running probe suite (static + memory reads only)");
    }
    Log("NOTE: run without dlc_enable.asi if both plugins fight over net hooks");

    RunAllProbes();
    RestoreAllRegPatches();
    /* Game may zero the flag during boot; re-apply before open-world / PMC exit spawn. */
    FixSpawnValidation();
    LogClose();
    return 0;
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
    (void)lpvReserved;

    if (fdwReason == DLL_PROCESS_ATTACH) {
        g_hModule = (HMODULE)hinstDLL;
        DisableThreadLibraryCalls(hinstDLL);
        LogInit();
        g_exeVerified = VerifyExeSize();
        /* Belt-and-suspenders if loaded without pmc_bb.dll (see pmc_blackbox DllMain). */
        FixSpawnValidation();
        Log("mercs2_probe.asi loaded (PID %d, exe_verified=%d)", GetCurrentProcessId(), g_exeVerified);
        Log("Build: RUNTIME_WALK=%d OBJECT_HOOK=%d", MERCS2_PROBE_RUNTIME_WALK, MERCS2_PROBE_OBJECT_HOOK);
        if (!g_exeVerified) {
            Log("WARNING: EXE size mismatch — VAs may not match this binary");
        }
#ifdef MERCS2_PROBE_MSGBOX
        MessageBoxA(NULL,
                    "mercs2_probe.asi loaded.\n\n"
                    "After ~15s, check scripts/probe_results/*.json",
                    "Mercs2 Probe", MB_OK | MB_ICONINFORMATION);
#endif
        CreateThread(NULL, 0, ProbeThread, NULL, 0, NULL);
    } else if (fdwReason == DLL_PROCESS_DETACH) {
        RestoreAllRegPatches();
    }
    return TRUE;
}
