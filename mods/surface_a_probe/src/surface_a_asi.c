/**
 * surface_a_asi.asi — Surface-A oracle: capture the ORIGINAL game's PARSED structs at a known
 * load-path boundary, so the 64-bit Rust reimplementation's parser can be diffed BYTE-FOR-BYTE
 * against ground truth. Standalone diagnostic ASI; does NOT touch pmc_bb / lua_trace / resprobe.
 *
 *   See docs/modernization/surface_a_oracle_design.md — "Surface A — asset -> struct".
 *
 * FIRST TARGET (A1): Mtrl_Parse = FUN_00858790 (__stdcall, ret 0x8).
 *   void __stdcall Mtrl_Parse(void *out_material [param_1], ChunkReader *reader [param_2]);
 *     reader (param_2):  cursor = *(reader+0x10) ; base = *(reader+0x18)
 *                        absolute read ptr = base + cursor ; parser advances cursor field-by-field.
 *     INPUT span consumed = [base + cursor_at_entry, base + cursor_at_exit).
 *     OUTPUT = out_material written in place; u16 tex-count @+0xa2, 10-slot {hash,0xF011157A,0}
 *              array @+0xac (stride 0x0c), tail floats up to +0x182. Capture 0x1C0 bytes covers it.
 *
 * The boundary is pure: parse(input_bytes) -> struct. Feed the Rust parser the same INPUT span and
 * assert the OUTPUT struct is byte-identical. Implementation is free; behaviour is gated.
 *
 * DESIGN (proven resprobe.c / lua_trace pattern):
 *   - A WRAPPING naked detour: on ENTRY save {out, reader, cursor_at_entry}; call the real parser
 *     via the MinHook trampoline; on RETURN read the finished OUTPUT struct + the consumed INPUT
 *     span and push ONE fixed-size record into a lock-free ring. ZERO I/O on the hot path.
 *   - A watcher thread drains the ring to surface_a.bin (length-delimited binary; struct bytes are
 *     the payload and must be verbatim, so binary not NDJSON) + surface_a.log diagnostics.
 *   - All game-memory reads are bounds-guarded (Readable + VirtualQuery), like lua_trace, so a bad
 *     pointer degrades to a skipped record, never an AV.
 *   - Dedupe by (target_va, input_crc32): a WAD ships each material once but it may be parsed many
 *     times; we want ONE golden record per distinct input (matches resprobe's Seen()).
 *
 * Addresses are for the DEPLOYED Mercenaries2.exe (image base 0x400000, no ASLR); exe-size guarded
 * like resprobe. Loaded by pmc_bb.dll / Ultimate ASI Loader from <game>/scripts/.
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include "MinHook.h"

/* ------------------------------------------------------------------ target config (A1) */
#define EXPECTED_EXE_SIZE   53482288
#define MTRL_PARSE_VA       0x00858790   /* Mtrl_Parse (__stdcall, ret 0x8) */

#define READER_CURSOR_OFF   0x10         /* *(reader+0x10) = byte cursor into chunk */
#define READER_BASE_OFF     0x18         /* *(reader+0x18) = chunk base ptr        */
#define MTRL_OUT_LEN        0x1C0        /* output-struct capture window (bytes)    */
#define INPUT_CAP           0x400        /* max input span bytes captured per record */

/* ------------------------------------------------------------------ record ring (hot path -> watcher) */
typedef struct {
    DWORD target_va;
    DWORD seq;
    DWORD input_len;
    DWORD input_crc32;
    DWORD output_len;
    BYTE  input[INPUT_CAP];
    BYTE  output[MTRL_OUT_LEN];
} Rec;

#define RING_CAP 4096                    /* power of two; circular, wrap-safe distance compare */
#define RING_MASK (RING_CAP - 1)
static Rec           g_ring[RING_CAP];
static volatile LONG g_head = 0;         /* records claimed (producers, atomic) */
static volatile LONG g_tail = 0;         /* records drained (single consumer/watcher) */
static volatile LONG g_committed[RING_CAP];  /* per-slot commit stamp = claimed index + 1 */
static volatile LONG g_dropped = 0;
static volatile LONG g_seqCtr  = 0;

/* Non-static so the naked detour asm can reference the MinHook trampoline. */
void *g_origMtrl = NULL;

static BOOL   g_exeOk = FALSE;
static HANDLE g_bin   = INVALID_HANDLE_VALUE;
static HANDLE g_log   = INVALID_HANDLE_VALUE;
typedef void (*pfn_pmc_log)(const char *source, const char *fmt, ...);
static pfn_pmc_log g_pmc_log = NULL;

/* ------------------------------------------------------------------ helpers */
static int Readable(DWORD p) { return p >= 0x10000 && p < 0x7FFF0000; }

/* Confirm [p, p+len) is committed + readable in ONE region (no NO_ACCESS crossing). */
static int RangeReadable(DWORD p, DWORD len)
{
    MEMORY_BASIC_INFORMATION mbi;
    if (!Readable(p) || len == 0) return 0;
    if (VirtualQuery((LPCVOID)p, &mbi, sizeof mbi) != sizeof mbi) return 0;
    if (mbi.State != MEM_COMMIT) return 0;
    if (!(mbi.Protect & (PAGE_READONLY | PAGE_READWRITE | PAGE_EXECUTE_READ |
                         PAGE_EXECUTE_READWRITE | PAGE_WRITECOPY | PAGE_EXECUTE_WRITECOPY))) return 0;
    if (mbi.Protect & PAGE_GUARD) return 0;
    DWORD regEnd = (DWORD)mbi.BaseAddress + (DWORD)mbi.RegionSize;
    return (p + len <= regEnd);
}

/* CRC32 (IEEE, reflected) — fast identity key for the input span. */
static DWORD Crc32(const BYTE *b, DWORD n)
{
    DWORD c = 0xFFFFFFFFu, i, k;
    for (i = 0; i < n; i++) {
        c ^= b[i];
        for (k = 0; k < 8; k++) c = (c >> 1) ^ (0xEDB88320u & (DWORD)(-(LONG)(c & 1)));
    }
    return ~c;
}

/* ---- dedupe: one record per (target_va, input_crc32) ---- */
#define SEEN_CAP 65536                   /* power of two */
static volatile LONG g_seen[SEEN_CAP];
static int Seen(DWORD crc)
{
    DWORD key = crc ? crc : 0xFFFFFFFFu;
    DWORD slot = (key * 2654435761u) & (SEEN_CAP - 1), p;
    for (p = 0; p < 64; p++) {
        DWORD idx = (slot + p) & (SEEN_CAP - 1);
        LONG cur = g_seen[idx];
        if ((DWORD)cur == key) return 1;
        if (cur == 0) {
            if (InterlockedCompareExchange(&g_seen[idx], (LONG)key, 0) == 0) return 0;
            if ((DWORD)g_seen[idx] == key) return 1;
        }
    }
    return 0;   /* table full within probe -> log again (harmless) */
}

/* ------------------------------------------------------------------ Record: hot path, ZERO I/O.
 * Called from the wrapping detour AFTER the real parser returned. out = param_1, reader = param_2,
 * cursorEntry = reader's byte cursor captured before the call. */
void __cdecl RecordMtrl(DWORD out, DWORD reader, DWORD cursorEntry)
{
    if (!Readable(reader) || !RangeReadable(reader + READER_BASE_OFF, 8)) return;
    DWORD base       = *(DWORD *)(reader + READER_BASE_OFF);
    DWORD cursorExit = *(DWORD *)(reader + READER_CURSOR_OFF);
    if (!Readable(base)) return;
    if (cursorExit <= cursorEntry) return;              /* nothing consumed / wrap -> skip */
    DWORD inLen = cursorExit - cursorEntry;
    if (inLen > INPUT_CAP) inLen = INPUT_CAP;           /* cap the captured input span */

    DWORD inPtr = base + cursorEntry;
    if (!RangeReadable(inPtr, inLen)) return;
    if (!RangeReadable(out, MTRL_OUT_LEN)) return;

    DWORD crc = Crc32((const BYTE *)inPtr, inLen);
    if (Seen(crc)) return;

    LONG idx = InterlockedIncrement(&g_head) - 1;
    if ((DWORD)(idx - g_tail) >= RING_CAP) { InterlockedIncrement(&g_dropped); return; }
    Rec *r = &g_ring[idx & RING_MASK];
    r->target_va   = MTRL_PARSE_VA;
    r->seq         = (DWORD)InterlockedIncrement(&g_seqCtr) - 1;
    r->input_len   = inLen;
    r->input_crc32 = crc;
    r->output_len  = MTRL_OUT_LEN;
    memcpy(r->input,  (const void *)inPtr, inLen);
    memcpy(r->output, (const void *)out, MTRL_OUT_LEN);

    MemoryBarrier();                                    /* publish fields before commit stamp */
    g_committed[idx & RING_MASK] = idx + 1;             /* watcher emits only when stamp == idx+1 */
}

/* ------------------------------------------------------------------ wrapping detour (naked)
 * Mtrl_Parse is stdcall(out, reader): [esp+4]=out, [esp+8]=reader, callee pops 8 (ret 0x8).
 * We WRAP: read reader's entry cursor, call the real parser via trampoline, then RecordMtrl with
 * the finished output + consumed span. We must preserve __stdcall semantics for our own caller
 * (i.e. pop the 8 arg bytes ourselves on the final ret). */
__attribute__((naked, used))
void Detour_Mtrl(void)
{
    __asm__ __volatile__ (
        "pushl %ebp\n\t"
        "movl  %esp, %ebp\n\t"          /* [ebp+8]=out, [ebp+12]=reader */
        "pushl %ebx\n\t"
        "pushl %esi\n\t"
        "pushl %edi\n\t"
        /* capture cursor_at_entry = *(reader + READER_CURSOR_OFF) ; guard reader first */
        "movl  12(%ebp), %esi\n\t"      /* esi = reader */
        "xorl  %edi, %edi\n\t"          /* edi = cursorEntry (0 if unreadable) */
        "cmpl  $0x10000, %esi\n\t"
        "jb    1f\n\t"
        "movl  " "0x10" "(%esi), %edi\n\t"  /* READER_CURSOR_OFF */
        "1:\n\t"
        /* call the real __stdcall parser: push reader, out (it pops them) */
        "pushl 12(%ebp)\n\t"
        "pushl 8(%ebp)\n\t"
        "call  *_g_origMtrl\n\t"        /* trampoline; __stdcall -> args popped by callee */
        /* record: RecordMtrl(out, reader, cursorEntry) is __cdecl -> we clean up */
        "pushl %edi\n\t"                /* cursorEntry */
        "pushl 12(%ebp)\n\t"           /* reader */
        "pushl 8(%ebp)\n\t"            /* out */
        "call  _RecordMtrl\n\t"
        "addl  $12, %esp\n\t"
        "popl  %edi\n\t"
        "popl  %esi\n\t"
        "popl  %ebx\n\t"
        "movl  %ebp, %esp\n\t"
        "popl  %ebp\n\t"
        "ret   $8\n\t"                  /* __stdcall: pop the 8 arg bytes for our caller */
    );
}

/* ------------------------------------------------------------------ file I/O (watcher thread only) */
static void OpenOutputs(void)
{
    char path[MAX_PATH], *slash;
    GetModuleFileNameA(NULL, path, MAX_PATH);
    slash = strrchr(path, '\\');
    if (slash) strcpy(slash + 1, "surface_a.bin"); else strcpy(path, "surface_a.bin");
    g_bin = CreateFileA(path, GENERIC_WRITE, FILE_SHARE_READ, NULL,
                        CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (g_bin != INVALID_HANDLE_VALUE) {
        BYTE hdr[8] = { 'S','A','1',0, 1,0,0,0 };   /* magic "SA1\0" + version u32=1 */
        DWORD w; WriteFile(g_bin, hdr, sizeof hdr, &w, NULL);
    }
    GetModuleFileNameA(NULL, path, MAX_PATH);
    slash = strrchr(path, '\\');
    if (slash) strcpy(slash + 1, "surface_a.log"); else strcpy(path, "surface_a.log");
    g_log = CreateFileA(path, GENERIC_WRITE, FILE_SHARE_READ, NULL,
                        CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    HMODULE bb = GetModuleHandleA("pmc_bb.dll");
    if (bb) g_pmc_log = (pfn_pmc_log)GetProcAddress(bb, "pmc_log");
}

static void Log(const char *fmt, ...)
{
    char buf[600]; va_list ap; int len, hl; SYSTEMTIME st;
    GetLocalTime(&st);
    hl = wsprintfA(buf, "[%02d:%02d:%02d.%03d] ", st.wHour, st.wMinute, st.wSecond, st.wMilliseconds);
    va_start(ap, fmt); len = wvsprintfA(buf + hl, fmt, ap); va_end(ap);
    if (len <= 0) return;
    len += hl;
    if (g_log != INVALID_HANDLE_VALUE) {
        DWORD w; buf[len] = '\r'; buf[len + 1] = '\n';
        WriteFile(g_log, buf, len + 2, &w, NULL);
    }
}

/* Emit one length-delimited record: rec_len, target_va, seq, input_len, input_crc32, output_len,
 * input[], output[]. rec_len = bytes after the rec_len field itself. */
static void WriteRecord(Rec *r)
{
    if (g_bin == INVALID_HANDLE_VALUE) return;
    DWORD hdr[5] = { r->target_va, r->seq, r->input_len, r->input_crc32, r->output_len };
    DWORD rec_len = (DWORD)sizeof hdr + r->input_len + r->output_len;
    DWORD w;
    WriteFile(g_bin, &rec_len, 4, &w, NULL);
    WriteFile(g_bin, hdr, sizeof hdr, &w, NULL);
    WriteFile(g_bin, r->input,  r->input_len,  &w, NULL);
    WriteFile(g_bin, r->output, r->output_len, &w, NULL);
}

static DWORD WINAPI Watcher(LPVOID p)
{
    (void)p;
    for (;;) {
        Sleep(300);
        int any = 0;
        for (;;) {
            if (g_tail >= g_head) break;                  /* nothing claimed beyond tail */
            LONG t = g_tail;
            if (g_committed[t & RING_MASK] != t + 1) break;  /* claimed but not yet committed */
            WriteRecord(&g_ring[t & RING_MASK]);
            g_committed[t & RING_MASK] = 0;               /* free the slot for reuse */
            g_tail = t + 1;
            any = 1;
        }
        if (any && g_bin != INVALID_HANDLE_VALUE) FlushFileBuffers(g_bin);
        if (g_dropped) { Log("WARN ring overflow, dropped=%ld", (long)g_dropped); g_dropped = 0; }
    }
}

/* ------------------------------------------------------------------ install */
static BOOL VerifyExeSize(void)
{
    char path[MAX_PATH]; HANDLE h; DWORD size;
    GetModuleFileNameA(NULL, path, MAX_PATH);
    h = CreateFileA(path, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
    if (h == INVALID_HANDLE_VALUE) return FALSE;
    size = GetFileSize(h, NULL); CloseHandle(h);
    return (size == EXPECTED_EXE_SIZE);
}

static int InstallOne(DWORD va, void *detour, void **orig, const char *name)
{
    if (MH_CreateHook((LPVOID)(DWORD_PTR)va, detour, orig) != MH_OK) { Log("MH_CreateHook(%s) failed", name); return 0; }
    if (MH_EnableHook((LPVOID)(DWORD_PTR)va) != MH_OK)               { Log("MH_EnableHook(%s) failed", name); return 0; }
    Log("hook armed: %s @0x%08lX", name, (unsigned long)va);
    return 1;
}

static DWORD WINAPI InstallThread(LPVOID p)
{
    (void)p;
    Sleep(2500);                                          /* let the (cracked) exe map .text */
    if (MH_Initialize() != MH_OK) { Log("MH_Initialize failed"); return 0; }
    InstallOne(MTRL_PARSE_VA, (void *)Detour_Mtrl, (void **)&g_origMtrl, "FUN_00858790(Mtrl_Parse=A1)");
    Log("A1 armed: dumping {input span, output struct[0x%X]} per distinct material to surface_a.bin", MTRL_OUT_LEN);
    return 0;
}

BOOL WINAPI DllMain(HINSTANCE h, DWORD reason, LPVOID r)
{
    (void)r;
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(h);
        OpenOutputs();
        g_exeOk = VerifyExeSize();
        Log("============================================");
        Log("surface_a.asi loaded (PID %lu, exe_ok=%d) — Surface-A asset->struct oracle (A1 Mtrl_Parse)",
            (unsigned long)GetCurrentProcessId(), g_exeOk);
        if (!g_exeOk) { Log("REFUSING: EXE size != %d", EXPECTED_EXE_SIZE); Log("====="); return TRUE; }
        CreateThread(NULL, 0, Watcher, NULL, 0, NULL);
        CreateThread(NULL, 0, InstallThread, NULL, 0, NULL);
        Log("============================================");
    } else if (reason == DLL_PROCESS_DETACH) {
        if (g_bin != INVALID_HANDLE_VALUE) { FlushFileBuffers(g_bin); CloseHandle(g_bin); g_bin = INVALID_HANDLE_VALUE; }
        if (g_log != INVALID_HANDLE_VALUE) { CloseHandle(g_log); g_log = INVALID_HANDLE_VALUE; }
    }
    return TRUE;
}
