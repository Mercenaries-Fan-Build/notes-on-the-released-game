/**
 * lua_trace_asi.asi — Surface-B oracle: capture the ordered stream of Lua->engine C-binding
 * calls (name + args) the ORIGINAL game emits, so the 64-bit reimplementation can be proven
 * trace-equivalent. Standalone ASI; does NOT touch pmc_bb / engine_trace / any other probe.
 *
 *   See docs/modernization/00_charter.md  — "Surface B — script -> engine bindings".
 *
 * WHY a binding tracer (not a VM/dispatch hook): the script<->engine boundary is exactly the
 * luaL_Reg C-functions. If a script calls Player.SetCash(800000), the engine sees SetCash(num).
 * We record that. A reimplemented VM (even a newer Lua) is correct iff it emits the SAME ordered
 * sequence of (binding, args) for the same scenario. Implementation is free; behaviour is gated.
 *
 * DESIGN (proven resprobe.c pattern, generalised to N bindings):
 *   1. At load, walk the MAIN module's PE headers; for each initialised-data section (.rdata/.data)
 *      scan for luaL_Reg tables — runs of >=3 consecutive { const char* name, lua_CFunction f }
 *      pairs (name -> a valid identifier string in data, f -> a .text VA). NO hardcoded addresses,
 *      so this is robust across exe builds (cracked / retail / unpacked).
 *   2. By default skip the Lua stdlib + Scaleform/AS2 tables (string/table/coroutine/MovieClip/...);
 *      they are deterministic library funcs, not engine state. Set LUA_TRACE_STDLIB=1 to include.
 *   3. For each game binding, generate a 16-byte index thunk (mov eax,i ; jmp SharedDetour) and
 *      MinHook the cfunc to it. Inline hooks are timing-independent (work regardless of when the
 *      closures were created) — unlike a luaL_Reg pointer swap, which only works pre-registration.
 *   4. SharedDetour reads the binding index from EAX and L (lua_State*) from the cdecl arg slot,
 *      calls Record (ZERO I/O: reads argc + up to 4 args off the Lua stack into a lock-free ring),
 *      then tail-jumps to the real binding via its MinHook trampoline.
 *   5. A watcher thread drains the ring to lua_trace.ndjson (one JSON object per call) + a summary
 *      to pmc_log if present.
 *
 * Lua 5.1 layout assumptions (overridable by env for live tuning via x32dbg):
 *   lua_State.top  @ L+0x08   (LUA_TRACE_TOP_OFF)   — confirmed by dlc_enable.asi (top->value@+0)
 *   lua_State.base @ L+0x0C   (LUA_TRACE_BASE_OFF)  — inferred; argc sanity-guarded so a wrong
 *                                                     base never crashes, only blanks the args
 *   TValue = { Value value@+0 ; int tt@+4 } = 8 bytes ; lua_Number = float (this build)
 *   tt: 0 nil,1 bool,2 lightudata,3 NUMBER(float),4 STRING,5 table,6 func,7 udata,8 thread
 *   TString char data @ TString+0x10 (LUA_TRACE_TSTR_OFF)
 *
 * Loaded by Ultimate ASI Loader from <game>/scripts/. Scans at runtime — no exe-size lock.
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "MinHook.h"

/* ------------------------------------------------------------------ tunables (env-overridable) */
static DWORD g_topOff  = 0x08;
static DWORD g_baseOff = 0x0C;
static DWORD g_tstrOff = 0x10;
static int   g_traceStdlib = 0;

#define MAX_BINDINGS 2048
#define MAX_ARGS     4
#define STRCAP       24          /* captured string bytes per arg (NUL-terminated) */
#define RING_CAP     262144      /* MUST be a power of two — circular ring indexes with & RING_MASK */
#define RING_MASK    (RING_CAP - 1)
#define LINE_CAP     1024        /* max NDJSON line; caller must give FormatRec >= LINE_CAP bytes */

/* ------------------------------------------------------------------ per-binding registry */
static const char *g_names[MAX_BINDINGS];   /* name ptr into exe .rdata (stable for process life) */
static DWORD       g_rva  [MAX_BINDINGS];    /* cfunc RVA (unique identity, disambiguates names)   */
void              *g_orig [MAX_BINDINGS];    /* MinHook trampoline per binding (asm-referenced)     */
static int         g_nBind = 0;

/* ------------------------------------------------------------------ trace ring (hot path -> watcher) */
typedef struct {
    LONG  seq;
    DWORD ms;
    WORD  bind;
    short argc;
    BYTE  tag[MAX_ARGS];
    DWORD val[MAX_ARGS];          /* number: float bits ; bool: 0/1 ; else: raw */
    char  str[MAX_ARGS][STRCAP];  /* string args only */
} Rec;
static Rec           g_ring[RING_CAP];
static volatile LONG g_head = 0;       /* total records claimed (producers, atomic) */
static volatile LONG g_tail = 0;       /* total records drained (single consumer/watcher) */
static volatile LONG g_dropped = 0;
static DWORD         g_t0 = 0;

static HANDLE g_log = INVALID_HANDLE_VALUE;
typedef void (*pfn_pmc_log)(const char *source, const char *fmt, ...);
static pfn_pmc_log g_pmc_log = NULL;

/* main-module section bounds (for pointer validation) */
static DWORD g_textLo = 0, g_textHi = 0;
static DWORD g_rdLo   = 0, g_rdHi   = 0;   /* .rdata: committed, readable, holds all binding tables+names.
                                              NOT the whole image — SizeOfImage spans SecuROM sections whose
                                              pages can be NO_ACCESS and fault on deref. */

static int InText(DWORD va){ return va >= g_textLo && va < g_textHi; }
static int Readable(DWORD p){ return p >= 0x10000 && p < 0x7FFF0000; }

/* True if [p, p+n) is committed & readable. 2-slot region cache: the real lua_State*
 * and the Lua stack are both stable, so back-to-back calls hit the cache and skip the
 * VirtualQuery — a garbage pointer misses, gets queried, and is rejected without ever
 * dereferencing it. (Aligned-DWORD cache reads are atomic on x86, so the lockless
 * cross-thread check can only mis-hit into an already-committed region, never fault.) */
static DWORD g_okLo[2], g_okHi[2];
static int   g_okNext;
static int CommittedRange(DWORD p, DWORD n)
{
    MEMORY_BASIC_INFORMATION mbi;
    DWORD lo, hi;
    int i;
    for (i = 0; i < 2; i++)
        if (g_okHi[i] && p >= g_okLo[i] && p + n <= g_okHi[i]) return 1;
    if (VirtualQuery((LPCVOID)p, &mbi, sizeof mbi) != sizeof mbi) return 0;
    if (mbi.State != MEM_COMMIT) return 0;
    if (!(mbi.Protect & (PAGE_READONLY|PAGE_READWRITE|PAGE_EXECUTE_READ|
                         PAGE_EXECUTE_READWRITE|PAGE_WRITECOPY|PAGE_EXECUTE_WRITECOPY))) return 0;
    if (mbi.Protect & PAGE_GUARD) return 0;
    lo = (DWORD)mbi.BaseAddress; hi = lo + (DWORD)mbi.RegionSize;
    if (p < lo || p + n > hi) return 0;
    g_okLo[g_okNext] = lo; g_okHi[g_okNext] = hi; g_okNext ^= 1;
    return 1;
}

/* ------------------------------------------------------------------ Record: hot path, ZERO I/O */
void __cdecl Record(int bind, void *Lv)
{
    DWORD L = (DWORD)Lv;
    LONG idx = InterlockedIncrement(&g_head) - 1;
    /* circular ring: drop only if the producer would overwrite a slot the watcher hasn't drained.
     * (DWORD) cast makes the distance comparison wrap-safe. */
    if ((DWORD)(idx - g_tail) >= RING_CAP) { InterlockedIncrement(&g_dropped); return; }
    Rec *r = &g_ring[idx & RING_MASK];
    r->ms   = GetTickCount() - g_t0;
    r->bind = (WORD)bind;
    r->argc = -1;
    r->tag[0]=r->tag[1]=r->tag[2]=r->tag[3]=0xFF;

    /* Single commit point at the end: EVERY path must reach `r->seq = idx`, else a claimed-but-
     * uncommitted slot would stall the consumer forever. So the arg parse is nested, not early-return. */
    /* Committed-memory gate (not just the loose Readable range): a garbage lua_State*
     * — e.g. a co-hooked binding whose arg slot isn't a clean L — can pass the range
     * test yet point at an UNMAPPED page, so the L->top read below would AV (seen only
     * on certain script paths). Rejecting it here turns that crash into a benign record
     * that still names the binding. To tell the FORMERLY-CRASHING calls apart from
     * ordinary co-hook noise, an unmapped L is stamped argc=-2 (vs the plain argc=-1 of
     * a committed-but-unclean L) — grep `"argc":-2` in the ndjson to name the culprit. */
    if (CommittedRange(L + g_topOff, 4) && CommittedRange(L + g_baseOff, 4)) {
        DWORD top  = *(DWORD *)(L + g_topOff);
        DWORD base = *(DWORD *)(L + g_baseOff);
        if (Readable(top) && Readable(base) && top >= base) {
            long n = (long)(top - base) / 8;
            if (n >= 0 && n <= 250) {             /* wrong base -> skip args, argc=-1, keep order */
                r->argc = (short)n;
                long k, kn = n < MAX_ARGS ? n : MAX_ARGS;
                if (kn > 0 && !CommittedRange(base, (DWORD)kn * 8)) kn = 0;  /* stack span unmapped -> keep argc, blank args */
                for (k = 0; k < kn; k++) {
                    DWORD slot = base + (DWORD)k * 8;
                    DWORD v  = *(DWORD *)(slot + 0);
                    DWORD tt = *(DWORD *)(slot + 4);
                    r->tag[k] = (BYTE)tt;
                    r->val[k] = v;
                    if (tt == 4 && Readable(v)) {  /* string: copy bytes from TString data */
                        const char *s = (const char *)(v + g_tstrOff);
                        /* A value mis-tagged as string yields a bogus s that may sit near an unmapped
                         * page -> AV. VirtualQuery confirms s's page is committed+readable and caps the
                         * read to the region end so we never cross into a NO_ACCESS neighbour. */
                        MEMORY_BASIC_INFORMATION mbi;
                        if (VirtualQuery(s, &mbi, sizeof mbi) == sizeof mbi && mbi.State == MEM_COMMIT &&
                            (mbi.Protect & (PAGE_READONLY|PAGE_READWRITE|PAGE_EXECUTE_READ|
                                            PAGE_EXECUTE_READWRITE|PAGE_WRITECOPY|PAGE_EXECUTE_WRITECOPY)) &&
                            !(mbi.Protect & PAGE_GUARD)) {
                            DWORD regEnd = (DWORD)mbi.BaseAddress + (DWORD)mbi.RegionSize;
                            int cap = STRCAP - 1;
                            if ((DWORD)s + cap > regEnd) cap = (int)(regEnd - (DWORD)s);
                            int j = 0;
                            for (; j < cap; j++) {
                                char c = s[j];
                                if (c == 0) break;
                                r->str[k][j] = (c >= 32 && c < 127) ? c : '?';
                            }
                            r->str[k][j] = 0;
                        }
                    }
                }
            }
        }
    } else {
        r->argc = -2;    /* L unmapped — this call would have AV'd pre-fix; flags the culprit binding */
    }
    MemoryBarrier();      /* publish all field writes before the commit stamp */
    r->seq = idx;         /* COMMIT: watcher emits this slot only when seq == its tail */
}

/* ------------------------------------------------------------------ shared detour (naked) */
/* Entry: EAX = binding index. Stack: [esp]=retaddr, [esp+4]=L (cdecl lua_CFunction arg).        */
__attribute__((naked, used))
void SharedDetour(void)
{
    __asm__ __volatile__ (
        "pushl %eax\n\t"              /* save index ; stack: [esp]=i [esp+4]=ret [esp+8]=L */
        "movl  8(%esp), %ecx\n\t"     /* ecx = L */
        "pushl %ecx\n\t"              /* arg2 = L */
        "pushl %eax\n\t"              /* arg1 = index */
        "call  _Record\n\t"
        "addl  $8, %esp\n\t"
        "popl  %eax\n\t"             /* restore index ; stack back to [esp]=ret [esp+4]=L */
        "jmp   *_g_orig(,%eax,4)\n\t" /* tail-jump to real binding via its trampoline */
    );
}

/* ------------------------------------------------------------------ logging (watcher only) */
static void LogInit(void)
{
    char path[MAX_PATH], *slash;
    GetModuleFileNameA(NULL, path, MAX_PATH);
    slash = strrchr(path, '\\');
    if (slash) strcpy(slash + 1, "lua_trace.ndjson"); else strcpy(path, "lua_trace.ndjson");
    g_log = CreateFileA(path, GENERIC_WRITE, FILE_SHARE_READ, NULL,
                        CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    HMODULE bb = GetModuleHandleA("pmc_bb.dll");
    if (bb) g_pmc_log = (pfn_pmc_log)GetProcAddress(bb, "pmc_log");
}

static void WriteLine(const char *buf, int len)
{
    if (g_log != INVALID_HANDLE_VALUE) { DWORD w; WriteFile(g_log, buf, len, &w, NULL); }
}

/* JSON-escape a captured (already printable) string into dst. */
static int JEsc(char *dst, const char *src)
{
    int o = 0;
    for (; *src && o < STRCAP * 2 - 2; src++) {
        if (*src == '"' || *src == '\\') dst[o++] = '\\';
        dst[o++] = *src;
    }
    dst[o] = 0;
    return o;
}

/* Format one record as an NDJSON line into `line` (needs >= LINE_CAP bytes); returns bytes written. */
static int FormatRec(Rec *r, char *line)
{
    const char *nm = (r->bind < g_nBind) ? g_names[r->bind] : "?";
    int o = wsprintfA(line, "{\"seq\":%ld,\"ms\":%lu,\"fn\":\"%s\",\"rva\":\"0x%lx\",\"argc\":%d,\"args\":[",
                      (long)r->seq, (unsigned long)r->ms, nm,
                      (unsigned long)(r->bind < g_nBind ? g_rva[r->bind] : 0), (int)r->argc);
    int kn = r->argc < 0 ? 0 : (r->argc < MAX_ARGS ? r->argc : MAX_ARGS);
    int k;
    for (k = 0; k < kn; k++) {
        if (k) line[o++] = ',';
        BYTE tt = r->tag[k];
        if (tt == 3) {                               /* number (float) */
            float f; memcpy(&f, &r->val[k], 4);
            /* print integral floats without a fraction for clean diffing */
            if (f == (float)(long long)f && f < 1e15f && f > -1e15f)
                o += wsprintfA(line + o, "{\"t\":\"num\",\"v\":%I64d}", (__int64)(long long)f);  /* wsprintfA needs I64, not lld */
            else {
                char fb[40]; snprintf(fb, sizeof fb, "%.6g", f);
                o += wsprintfA(line + o, "{\"t\":\"num\",\"v\":%s}", fb);
            }
        } else if (tt == 4) {                        /* string */
            char esc[STRCAP * 2]; JEsc(esc, r->str[k]);
            o += wsprintfA(line + o, "{\"t\":\"str\",\"v\":\"%s\"}", esc);
        } else if (tt == 1) {                        /* boolean */
            o += wsprintfA(line + o, "{\"t\":\"bool\",\"v\":%s}", r->val[k] ? "true" : "false");
        } else if (tt == 0) {
            o += wsprintfA(line + o, "{\"t\":\"nil\"}");
        } else {                                     /* table/func/udata/thread/light */
            o += wsprintfA(line + o, "{\"t\":\"tt%d\",\"p\":\"0x%lx\"}", (int)tt, (unsigned long)r->val[k]);
        }
        if (o > LINE_CAP - 80) break;                /* truncate pathological arg lists (NOT sizeof(ptr)) */
    }
    line[o++] = ']'; line[o++] = '}'; line[o++] = '\r'; line[o++] = '\n';
    return o;
}

static char g_wbuf[1 << 20];   /* 1 MiB batch buffer; single consumer (watcher) -> no lock needed */

static DWORD WINAPI Watcher(LPVOID p)
{
    (void)p;
    for (;;) {
        Sleep(100);
        int wo = 0, any = 0;
        for (;;) {
            if (g_tail >= g_head) break;              /* nothing claimed beyond tail */
            Rec *r = &g_ring[g_tail & RING_MASK];
            if (r->seq != g_tail) break;              /* claimed but not yet committed */
            if (wo > (int)sizeof(g_wbuf) - 1200) {    /* flush batch before it can overflow */
                if (g_log != INVALID_HANDLE_VALUE) { DWORD w; WriteFile(g_log, g_wbuf, wo, &w, NULL); }
                wo = 0;
            }
            wo += FormatRec(r, g_wbuf + wo);
            g_tail++;                                 /* publish progress -> frees the slot for reuse */
            any = 1;
        }
        if (wo && g_log != INVALID_HANDLE_VALUE) { DWORD w; WriteFile(g_log, g_wbuf, wo, &w, NULL); }
        if (any && g_log != INVALID_HANDLE_VALUE) FlushFileBuffers(g_log);
        if (g_dropped) {
            char w[96]; int n = wsprintfA(w, "{\"warn\":\"ring overflow\",\"dropped\":%ld}\r\n", (long)g_dropped);
            WriteLine(w, n); g_dropped = 0;
        }
    }
}

/* ------------------------------------------------------------------ PE scan for luaL_Reg tables */
static int IsIdentStr(DWORD va)
{
    if (va < g_rdLo || va >= g_rdHi - 48) return 0;   /* in .rdata w/ headroom; subtract to avoid the
                                                         va+48 32-bit overflow when va is a 0xFFFFFFFF
                                                         sentinel (that wrapped past the guard -> AV) */
    const char *s = (const char *)va;
    char c = s[0];
    if (!((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || c == '_')) return 0;
    int i;
    for (i = 1; i < 48; i++) {
        c = s[i];
        if (c == 0) return i >= 2;
        if (!((c>='A'&&c<='Z')||(c>='a'&&c<='z')||(c>='0'&&c<='9')||c=='_')) return 0;
    }
    return 0;   /* too long -> not a binding name */
}

/* default-skip the Lua stdlib + Scaleform/AS2 tables: skip a table if any name is a known marker */
static int IsStdlibName(const char *n)
{
    static const char *mk[] = {
        "collectgarbage","gsub","gmatch","gfind","setmetatable","rawget","gcinfo",
        "resume","yield","gotoAndStop","getFullYear","createGradientBox","deltaTransformPoint",
        "POSITIVE_INFINITY","attachSound","beginFill","getBytesTotal", NULL };
    int i; for (i = 0; mk[i]; i++) if (!strcmp(n, mk[i])) return 1;
    return 0;
}

static void Log(const char *fmt, ...)
{
    char buf[400]; va_list ap; int len; SYSTEMTIME st;
    GetLocalTime(&st);
    len = wsprintfA(buf, "{\"_log\":\"%02d:%02d:%02d.%03d ", st.wHour, st.wMinute, st.wSecond, st.wMilliseconds);
    va_start(ap, fmt); len += wvsprintfA(buf + len, fmt, ap); va_end(ap);
    len += wsprintfA(buf + len, "\"}\r\n");
    WriteLine(buf, len);
    if (g_pmc_log) { /* strip to plain for pmc_log */ }
}

static BYTE *g_thunks = NULL;

static int InstallBinding(const char *name, DWORD cfuncVA, DWORD imgBase)
{
    if (g_nBind >= MAX_BINDINGS) return 0;
    int idx = g_nBind;
    /* 16-byte thunk: B8 <idx> ; E9 <rel32 to SharedDetour> ; pad CC */
    BYTE *t = g_thunks + idx * 16;
    DWORD rel = (DWORD)((BYTE *)&SharedDetour - (t + 10));
    t[0] = 0xB8; *(DWORD *)(t + 1) = (DWORD)idx;
    t[5] = 0xE9; *(DWORD *)(t + 6) = rel;
    memset(t + 10, 0xCC, 6);

    if (MH_CreateHook((LPVOID)(DWORD_PTR)cfuncVA, (LPVOID)t, &g_orig[idx]) != MH_OK) return 0;
    if (MH_EnableHook((LPVOID)(DWORD_PTR)cfuncVA) != MH_OK) return 0;
    g_names[idx] = name;
    g_rva[idx]   = cfuncVA - imgBase;
    g_nBind++;
    return 1;
}

static void ScanAndHook(void)
{
    BYTE *base = (BYTE *)GetModuleHandleA(NULL);
    IMAGE_DOS_HEADER *dos = (IMAGE_DOS_HEADER *)base;
    IMAGE_NT_HEADERS *nt  = (IMAGE_NT_HEADERS *)(base + dos->e_lfanew);
    DWORD imgBase = (DWORD)base;   /* non-relocated; ImageBase 0x400000 == load addr */
    IMAGE_SECTION_HEADER *sec = IMAGE_FIRST_SECTION(nt);
    int nsec = nt->FileHeader.NumberOfSections, s;

    /* locate .text (cfunc validation) and .rdata (table+name scan) bounds */
    for (s = 0; s < nsec; s++) {
        if (!memcmp(sec[s].Name, ".text", 5)) {
            g_textLo = (DWORD)base + sec[s].VirtualAddress;
            g_textHi = g_textLo + sec[s].Misc.VirtualSize;
        } else if (!memcmp(sec[s].Name, ".rdata", 6)) {
            g_rdLo = (DWORD)base + sec[s].VirtualAddress;
            g_rdHi = g_rdLo + sec[s].Misc.VirtualSize;
        }
    }
    if (!g_textLo || !g_rdLo) { Log("missing .text/.rdata — abort"); return; }
    Log(".text %08lx-%08lx  .rdata %08lx-%08lx", (unsigned long)g_textLo, (unsigned long)g_textHi,
        (unsigned long)g_rdLo, (unsigned long)g_rdHi);

    int tablesGame = 0, tablesSkip = 0;
    for (s = 0; s < nsec; s++) {
        if (memcmp(sec[s].Name, ".rdata", 6)) continue;   /* all real binding tables live in .rdata */
        DWORD lo = (DWORD)base + sec[s].VirtualAddress;
        DWORD sz = sec[s].Misc.VirtualSize;
        DWORD off;
        for (off = 0; off + 8 <= sz; off += 4) {
            DWORD p = lo + off;
            DWORD a = *(DWORD *)p, b = *(DWORD *)(p + 4);
            if (!(IsIdentStr(a) && InText(b))) continue;
            /* found a pair — measure the consecutive run (stride 8) */
            DWORD q = p, cnt = 0;
            const char *names[256]; DWORD funcs[256];
            while (cnt < 256) {
                DWORD aa = *(DWORD *)q, bb = *(DWORD *)(q + 4);
                if (!(IsIdentStr(aa) && InText(bb))) break;
                names[cnt] = (const char *)aa; funcs[cnt] = bb; cnt++;
                q += 8;
            }
            if (cnt >= 3) {
                int skip = 0, j;
                if (!g_traceStdlib)
                    for (j = 0; j < (int)cnt; j++) if (IsStdlibName(names[j])) { skip = 1; break; }
                if (skip) { tablesSkip++; }
                else {
                    tablesGame++;
                    for (j = 0; j < (int)cnt; j++) {
                        /* skip duplicate cfunc addrs (shared dispatchers) */
                        int dup = 0, m;
                        for (m = 0; m < g_nBind; m++) if (g_rva[m] + imgBase == funcs[j]) { dup = 1; break; }
                        if (!dup) InstallBinding(names[j], funcs[j], imgBase);
                    }
                    /* progress: bisects scan-fault vs hook-fault if the game dies mid-install */
                    Log("table %d [%s] n=%lu -> hooked total %d", tablesGame, names[0],
                        (unsigned long)cnt, g_nBind);
                }
                off += (cnt - 1) * 8;   /* advance past the table */
            }
        }
    }
    Log("scan done: hooked %d bindings across %d game tables (skipped %d stdlib/scaleform tables)",
        g_nBind, tablesGame, tablesSkip);
}

/* ------------------------------------------------------------------ env config */
static void EnvCfg(void)
{
    char b[32];
    if (GetEnvironmentVariableA("LUA_TRACE_TOP_OFF",  b, sizeof b)) g_topOff  = strtoul(b, 0, 0);
    if (GetEnvironmentVariableA("LUA_TRACE_BASE_OFF", b, sizeof b)) g_baseOff = strtoul(b, 0, 0);
    if (GetEnvironmentVariableA("LUA_TRACE_TSTR_OFF", b, sizeof b)) g_tstrOff = strtoul(b, 0, 0);
    if (GetEnvironmentVariableA("LUA_TRACE_STDLIB",   b, sizeof b)) g_traceStdlib = atoi(b);
}

static DWORD WINAPI InstallThread(LPVOID p)
{
    (void)p;
    /* small delay: let the (cracked) exe finish mapping/decrypting .text before we hook it */
    Sleep(2500);
    if (MH_Initialize() != MH_OK) { Log("MH_Initialize failed"); return 0; }
    g_thunks = (BYTE *)VirtualAlloc(NULL, MAX_BINDINGS * 16, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!g_thunks) { Log("thunk alloc failed"); return 0; }
    ScanAndHook();
    return 0;
}

BOOL WINAPI DllMain(HINSTANCE h, DWORD reason, LPVOID r)
{
    (void)r;
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(h);
        g_t0 = GetTickCount();
        EnvCfg();
        LogInit();
        /* seq sentinel: -1 so an untouched slot never equals its expected tail index (esp. slot 0
         * vs committed record 0). Must run before the watcher/producers start. */
        { LONG i; for (i = 0; i < RING_CAP; i++) g_ring[i].seq = -1; }
        Log("lua_trace.asi loaded (PID %lu) — Surface-B binding-call oracle. top@+%lx base@+%lx tstr@+%lx stdlib=%d",
            (unsigned long)GetCurrentProcessId(),
            (unsigned long)g_topOff, (unsigned long)g_baseOff, (unsigned long)g_tstrOff, g_traceStdlib);
        CreateThread(NULL, 0, Watcher, NULL, 0, NULL);
        CreateThread(NULL, 0, InstallThread, NULL, 0, NULL);
    } else if (reason == DLL_PROCESS_DETACH) {
        if (g_log != INVALID_HANDLE_VALUE) { FlushFileBuffers(g_log); CloseHandle(g_log); g_log = INVALID_HANDLE_VALUE; }
    }
    return TRUE;
}
