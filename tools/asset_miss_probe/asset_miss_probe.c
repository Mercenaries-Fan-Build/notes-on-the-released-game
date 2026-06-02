/**
 * asset_miss_probe.asi — File-open failure tracer for Mercenaries 2: World in Flames
 *
 * Standalone diagnostic ASI (NOT coupled to dlc_enable.asi). Loaded by pmc_bb.dll /
 * Ultimate ASI Loader from <game>/scripts/ (LoadLibraryA — no exports required).
 *
 * Purpose
 * -------
 * We are debugging a GlobalEnter spin where the engine streaming worker at
 * mercenaries2.exe+0x876400 retries a file/asset lookup that returns
 * STATUS_OBJECT_NAME_NOT_FOUND (0xC0000034). This probe hooks the file-open path
 * and logs the FAILING path plus the game-side caller return address, so we can
 * confirm the miss traces back to the 0x876400 worker and learn WHICH asset/file
 * the engine cannot find.
 *
 * What it hooks
 * -------------
 *   - IAT of mercenaries2.exe: kernel32!CreateFileW + kernel32!CreateFileA
 *     (immediate caller = game code — best signal for the 0x876400 worker).
 *   - Inline hook of ntdll!NtCreateFile + ntdll!NtOpenFile
 *     (catches STATUS_OBJECT_NAME_NOT_FOUND directly; clean 5-byte
 *      `mov eax, imm32` prologue boundary, so no length disassembler needed).
 *
 * Throttling
 * ----------
 * The worker SPINS, so the same failing path repeats thousands of times. We log
 * the FIRST occurrence of each unique failing path (up to MISS_MAX_UNIQUE), bump a
 * per-path hit counter on repeats (no log), and emit ONE periodic summary line
 * every MISS_PERIODIC total failures. The success path does no work beyond calling
 * the real function. No per-call VirtualQuery.
 *
 * Safety
 * ------
 *   - EXE-size gate (cracked retail 53,482,288 bytes) — refuses to hook on mismatch.
 *   - TLS reentrancy guard so logging cannot recurse through the hooks.
 *   - Lightweight spinlock only taken when registering a NEW unique path (rare).
 *   - Resolves pmc_bb.dll!pmc_log; falls back to asset_miss_probe.log next to the EXE.
 *
 * Build (32-bit / x86 to match the game):
 *   make -C tools/asset_miss_probe mingw
 *   make asset-miss-probe OUTPUT=./output
 *
 * NOTE: the bundled msvc/ toolchain is x64-only and cannot emit a 32-bit DLL; the
 * project builds its 32-bit ASIs with MinGW i686 (same as tools/mercs2_probe). An
 * `msvc` target is provided for completeness on a machine with an x86 MSVC install.
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

/* --- EXE layout (cracked retail 53,482,288 bytes, image base 0x00400000) ---
 * Constants confirmed from tools/mercs2_probe/mercs2_probe.c. */

#define EXPECTED_EXE_SIZE       53482288
#define IMAGE_BASE              0x00400000

#define TEXT_START_VA           0x00401000
#define TEXT_SIZE               0x00703000      /* .text end = 0x00B04000 */

/* The streaming worker we are chasing (for annotation only). */
#define WORKER_VA               0x00876400

/* --- Throttle configuration --- */

#define MISS_MAX_UNIQUE         64      /* distinct failing paths logged in full */
#define MISS_PATH_MAX           512     /* stored/logged path length cap (chars) */
#define MISS_PERIODIC           2000    /* emit a summary every N total failures */
#define MISS_STACK_SCAN_DWORDS  96      /* stack slots scanned for a game caller */

/* NTSTATUS codes of interest */
#define STATUS_OBJECT_NAME_NOT_FOUND  ((LONG)0xC0000034L)
#define STATUS_OBJECT_PATH_NOT_FOUND  ((LONG)0xC000003AL)

/* --- Minimal NT types (avoid winternl.h to prevent prototype clashes) --- */

typedef LONG NTSTATUS;

typedef struct _MISS_UNICODE_STRING {
    USHORT Length;          /* bytes, NOT including terminator */
    USHORT MaximumLength;
    PWSTR  Buffer;
} MISS_UNICODE_STRING;

typedef struct _MISS_OBJECT_ATTRIBUTES {
    ULONG  Length;
    HANDLE RootDirectory;
    MISS_UNICODE_STRING* ObjectName;
    ULONG  Attributes;
    PVOID  SecurityDescriptor;
    PVOID  SecurityQualityOfService;
} MISS_OBJECT_ATTRIBUTES;

typedef NTSTATUS (WINAPI *pfn_NtCreateFile)(
    PHANDLE FileHandle, ACCESS_MASK DesiredAccess, MISS_OBJECT_ATTRIBUTES* ObjectAttributes,
    PVOID IoStatusBlock, PLARGE_INTEGER AllocationSize, ULONG FileAttributes,
    ULONG ShareAccess, ULONG CreateDisposition, ULONG CreateOptions,
    PVOID EaBuffer, ULONG EaLength);

typedef NTSTATUS (WINAPI *pfn_NtOpenFile)(
    PHANDLE FileHandle, ACCESS_MASK DesiredAccess, MISS_OBJECT_ATTRIBUTES* ObjectAttributes,
    PVOID IoStatusBlock, ULONG ShareAccess, ULONG OpenOptions);

typedef HANDLE (WINAPI *pfn_CreateFileW)(LPCWSTR, DWORD, DWORD, LPSECURITY_ATTRIBUTES,
                                         DWORD, DWORD, HANDLE);
typedef HANDLE (WINAPI *pfn_CreateFileA)(LPCSTR, DWORD, DWORD, LPSECURITY_ATTRIBUTES,
                                         DWORD, DWORD, HANDLE);

/* --- Globals --- */

static HMODULE g_hModule = NULL;
static BOOL    g_exeVerified = FALSE;
static BOOL    g_hooksInstalled = FALSE;
static DWORD   g_tlsGuard = TLS_OUT_OF_INDEXES;

static pfn_CreateFileW g_realCreateFileW = NULL;
static pfn_CreateFileA g_realCreateFileA = NULL;
static pfn_NtCreateFile g_realNtCreateFile = NULL;  /* trampoline */
static pfn_NtOpenFile   g_realNtOpenFile = NULL;     /* trampoline */

/* --- Logging (pmc_log with own-file fallback, mirrors dlc_enable.c) --- */

#define MISS_LOG_SOURCE "asset_miss"

typedef void (*pfn_pmc_log)(const char* source, const char* fmt, ...);
static pfn_pmc_log g_pmc_log = NULL;
static HANDLE g_fallbackLog = INVALID_HANDLE_VALUE;

static void LogInit(void) {
    HMODULE hBlackbox = GetModuleHandleA("pmc_bb.dll");
    if (hBlackbox) {
        g_pmc_log = (pfn_pmc_log)GetProcAddress(hBlackbox, "pmc_log");
    }
    if (!g_pmc_log) {
        char path[MAX_PATH];
        char* dot;
        GetModuleFileNameA(g_hModule, path, MAX_PATH);
        dot = strrchr(path, '.');
        if (dot) strcpy(dot, ".log");
        else strcat(path, ".log");
        g_fallbackLog = CreateFileA(path, GENERIC_WRITE, FILE_SHARE_READ,
                                    NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    }
}

static void Log(const char* fmt, ...) {
    char buf[1200];
    va_list ap;
    int len;

    va_start(ap, fmt);
    len = wvsprintfA(buf, fmt, ap);
    va_end(ap);
    if (len <= 0) return;

    if (g_pmc_log) {
        g_pmc_log(MISS_LOG_SOURCE, "%s", buf);
    } else if (g_fallbackLog != INVALID_HANDLE_VALUE) {
        DWORD written;
        buf[len] = '\r';
        buf[len + 1] = '\n';
        WriteFile(g_fallbackLog, buf, len + 2, &written, NULL);
        FlushFileBuffers(g_fallbackLog);
    }
}

/* --- EXE-size gate (identical constant to mercs2_probe.c) --- */

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

/* --- Throttle / de-dup table --- */

typedef struct {
    DWORD          hash;
    volatile LONG  hits;
    char           path[MISS_PATH_MAX];
} MissEntry;

static MissEntry    g_unique[MISS_MAX_UNIQUE];
static volatile LONG g_uniqueCount = 0;
static volatile LONG g_totalMisses = 0;
static volatile LONG g_lock = 0;

static void SpinLock(void) {
    while (InterlockedCompareExchange(&g_lock, 1, 0) != 0) {
        YieldProcessor();
    }
}

static void SpinUnlock(void) {
    InterlockedExchange(&g_lock, 0);
}

static DWORD HashPath(const char* s) {
    /* FNV-1a, case-insensitive (paths compare case-insensitively on Windows). */
    DWORD h = 2166136261u;
    while (*s) {
        char c = *s++;
        if (c >= 'A' && c <= 'Z') c = (char)(c + 32);
        h ^= (unsigned char)c;
        h *= 16777619u;
    }
    return h;
}

static int PathEqualCI(const char* a, const char* b) {
    return _stricmp(a, b) == 0;
}

/* Scan the raw stack upward from `anchor` for the first dword that lands inside
 * mercenaries2.exe .text — that is the game-side caller (the worker we want). */
static DWORD ScanGameCaller(void* anchor) {
    DWORD* sp = (DWORD*)anchor;
    int i;
    for (i = 0; i < MISS_STACK_SCAN_DWORDS; i++) {
        DWORD v = sp[i];
        if (v >= TEXT_START_VA && v < (TEXT_START_VA + TEXT_SIZE)) {
            return v;
        }
    }
    return 0;
}

/* Record one failing open. `code` is errno-style (CreateFile) or NTSTATUS (Nt*).
 * Cheap on repeats (lock-free scan + interlocked counters); logs only first
 * occurrence per unique path + a periodic summary. */
static void RecordMiss(const char* api, const char* path, DWORD code, DWORD caller) {
    LONG total;
    DWORD h;
    int n, i;

    if (!path || !path[0]) path = "(null)";
    total = InterlockedIncrement(&g_totalMisses);
    h = HashPath(path);

    /* Lock-free fast path: already-known unique path → bump and return. */
    n = (int)g_uniqueCount;
    for (i = 0; i < n && i < MISS_MAX_UNIQUE; i++) {
        if (g_unique[i].hash == h && PathEqualCI(g_unique[i].path, path)) {
            InterlockedIncrement(&g_unique[i].hits);
            goto periodic;
        }
    }

    /* New path — register under lock (re-check to avoid a race duplicate). */
    SpinLock();
    n = (int)g_uniqueCount;
    for (i = 0; i < n && i < MISS_MAX_UNIQUE; i++) {
        if (g_unique[i].hash == h && PathEqualCI(g_unique[i].path, path)) {
            InterlockedIncrement(&g_unique[i].hits);
            SpinUnlock();
            goto periodic;
        }
    }
    if (n < MISS_MAX_UNIQUE) {
        MissEntry* e = &g_unique[n];
        e->hash = h;
        e->hits = 1;
        strncpy(e->path, path, MISS_PATH_MAX - 1);
        e->path[MISS_PATH_MAX - 1] = '\0';
        InterlockedIncrement(&g_uniqueCount);
        SpinUnlock();
        if (caller) {
            Log("MISS #%d %s err=0x%08lX caller=0x%08lX%s path=%s",
                n + 1, api, (unsigned long)code, (unsigned long)caller,
                (caller == WORKER_VA) ? " (==worker 0x876400)" : "", e->path);
        } else {
            Log("MISS #%d %s err=0x%08lX caller=? path=%s",
                n + 1, api, (unsigned long)code, e->path);
        }
        if (n + 1 == MISS_MAX_UNIQUE) {
            Log("NOTE: unique-path table full (%d) — further new paths counted in totals only",
                MISS_MAX_UNIQUE);
        }
    } else {
        SpinUnlock();
    }

periodic:
    if ((total % MISS_PERIODIC) == 0) {
        int uc = (int)g_uniqueCount;
        Log("--- summary: total_failures=%ld unique_paths=%d ---", (long)total, uc);
        for (i = 0; i < uc && i < MISS_MAX_UNIQUE; i++) {
            Log("    [hits=%ld] %s", (long)g_unique[i].hits, g_unique[i].path);
        }
    }
}

/* --- Reentrancy guard --- */

static int GuardEnter(void) {
    if (g_tlsGuard == TLS_OUT_OF_INDEXES) return 1; /* no guard available — proceed */
    if (TlsGetValue(g_tlsGuard)) return 0;          /* already inside our hook */
    TlsSetValue(g_tlsGuard, (LPVOID)1);
    return 1;
}

static void GuardLeave(void) {
    if (g_tlsGuard != TLS_OUT_OF_INDEXES) {
        TlsSetValue(g_tlsGuard, (LPVOID)0);
    }
}

/* --- Hook bodies --- */

static HANDLE WINAPI Hook_CreateFileW(LPCWSTR name, DWORD acc, DWORD share,
                                      LPSECURITY_ATTRIBUTES sa, DWORD disp,
                                      DWORD flags, HANDLE tmpl) {
    HANDLE h;
    int anchor = 0;

    if (!GuardEnter()) {
        return g_realCreateFileW(name, acc, share, sa, disp, flags, tmpl);
    }
    h = g_realCreateFileW(name, acc, share, sa, disp, flags, tmpl);
    if (h == INVALID_HANDLE_VALUE) {
        DWORD e = GetLastError();
        if (e == ERROR_FILE_NOT_FOUND || e == ERROR_PATH_NOT_FOUND) {
            char buf[MISS_PATH_MAX];
            int n = 0;
            if (name) {
                n = WideCharToMultiByte(CP_UTF8, 0, name, -1, buf, sizeof(buf) - 1, NULL, NULL);
            }
            if (n <= 0) buf[0] = '\0';
            RecordMiss("CreateFileW", buf, e, ScanGameCaller(&anchor));
        }
        GuardLeave();
        SetLastError(e);
        return h;
    }
    GuardLeave();
    return h;
}

static HANDLE WINAPI Hook_CreateFileA(LPCSTR name, DWORD acc, DWORD share,
                                      LPSECURITY_ATTRIBUTES sa, DWORD disp,
                                      DWORD flags, HANDLE tmpl) {
    HANDLE h;
    int anchor = 0;

    if (!GuardEnter()) {
        return g_realCreateFileA(name, acc, share, sa, disp, flags, tmpl);
    }
    h = g_realCreateFileA(name, acc, share, sa, disp, flags, tmpl);
    if (h == INVALID_HANDLE_VALUE) {
        DWORD e = GetLastError();
        if (e == ERROR_FILE_NOT_FOUND || e == ERROR_PATH_NOT_FOUND) {
            RecordMiss("CreateFileA", name ? name : "(null)", e, ScanGameCaller(&anchor));
        }
        GuardLeave();
        SetLastError(e);
        return h;
    }
    GuardLeave();
    return h;
}

/* Convert a (non-terminated) UNICODE_STRING ObjectName into UTF-8. */
static void ObjectNameToUtf8(MISS_OBJECT_ATTRIBUTES* oa, char* out, int out_max) {
    out[0] = '\0';
    if (!oa) return;
    /* OBJECT_ATTRIBUTES and ObjectName live on the caller's stack/heap; reading is
     * normally safe, but be defensive about obviously bad pointers. */
    if (IsBadReadPtr(oa, sizeof(*oa))) return;
    if (!oa->ObjectName || IsBadReadPtr(oa->ObjectName, sizeof(*oa->ObjectName))) return;
    {
        MISS_UNICODE_STRING* us = oa->ObjectName;
        int wlen = us->Length / 2;
        if (!us->Buffer || wlen <= 0) return;
        if (wlen > (MISS_PATH_MAX - 1)) wlen = MISS_PATH_MAX - 1;
        if (IsBadReadPtr(us->Buffer, (UINT_PTR)wlen * 2)) return;
        WideCharToMultiByte(CP_UTF8, 0, us->Buffer, wlen, out, out_max - 1, NULL, NULL);
        /* WideCharToMultiByte with explicit length does not NUL-terminate. */
        {
            int blen = WideCharToMultiByte(CP_UTF8, 0, us->Buffer, wlen, NULL, 0, NULL, NULL);
            if (blen < 0) blen = 0;
            if (blen > out_max - 1) blen = out_max - 1;
            out[blen] = '\0';
        }
    }
}

static NTSTATUS WINAPI Hook_NtCreateFile(PHANDLE FileHandle, ACCESS_MASK DesiredAccess,
                                         MISS_OBJECT_ATTRIBUTES* oa, PVOID iosb,
                                         PLARGE_INTEGER alloc, ULONG fattr, ULONG share,
                                         ULONG disp, ULONG opts, PVOID ea, ULONG ealen) {
    NTSTATUS st;
    int anchor = 0;

    if (!GuardEnter()) {
        return g_realNtCreateFile(FileHandle, DesiredAccess, oa, iosb, alloc, fattr,
                                  share, disp, opts, ea, ealen);
    }
    st = g_realNtCreateFile(FileHandle, DesiredAccess, oa, iosb, alloc, fattr,
                            share, disp, opts, ea, ealen);
    if (st == STATUS_OBJECT_NAME_NOT_FOUND || st == STATUS_OBJECT_PATH_NOT_FOUND) {
        char buf[MISS_PATH_MAX];
        ObjectNameToUtf8(oa, buf, sizeof(buf));
        RecordMiss("NtCreateFile", buf, (DWORD)st, ScanGameCaller(&anchor));
    }
    GuardLeave();
    return st;
}

static NTSTATUS WINAPI Hook_NtOpenFile(PHANDLE FileHandle, ACCESS_MASK DesiredAccess,
                                       MISS_OBJECT_ATTRIBUTES* oa, PVOID iosb,
                                       ULONG share, ULONG opts) {
    NTSTATUS st;
    int anchor = 0;

    if (!GuardEnter()) {
        return g_realNtOpenFile(FileHandle, DesiredAccess, oa, iosb, share, opts);
    }
    st = g_realNtOpenFile(FileHandle, DesiredAccess, oa, iosb, share, opts);
    if (st == STATUS_OBJECT_NAME_NOT_FOUND || st == STATUS_OBJECT_PATH_NOT_FOUND) {
        char buf[MISS_PATH_MAX];
        ObjectNameToUtf8(oa, buf, sizeof(buf));
        RecordMiss("NtOpenFile", buf, (DWORD)st, ScanGameCaller(&anchor));
    }
    GuardLeave();
    return st;
}

/* --- IAT hook installer (mercenaries2.exe import table) --- */

static int PatchIatSlot(void** slot, void* hook) {
    DWORD oldp;
    if (!VirtualProtect(slot, sizeof(void*), PAGE_READWRITE, &oldp)) return 0;
    *slot = hook;
    VirtualProtect(slot, sizeof(void*), oldp, &oldp);
    return 1;
}

static int InstallIatHooks(void) {
    BYTE* base = (BYTE*)GetModuleHandleA(NULL);
    IMAGE_DOS_HEADER* dos;
    IMAGE_NT_HEADERS* nt;
    IMAGE_DATA_DIRECTORY* dir;
    IMAGE_IMPORT_DESCRIPTOR* imp;
    int patched = 0;

    if (!base) return 0;
    dos = (IMAGE_DOS_HEADER*)base;
    if (dos->e_magic != IMAGE_DOS_SIGNATURE) return 0;
    nt = (IMAGE_NT_HEADERS*)(base + dos->e_lfanew);
    if (nt->Signature != IMAGE_NT_SIGNATURE) return 0;
    dir = &nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT];
    if (!dir->VirtualAddress || !dir->Size) return 0;

    imp = (IMAGE_IMPORT_DESCRIPTOR*)(base + dir->VirtualAddress);
    for (; imp->Name; imp++) {
        IMAGE_THUNK_DATA* thunk = (IMAGE_THUNK_DATA*)(base + imp->FirstThunk);
        for (; thunk->u1.Function; thunk++) {
            void** slot = (void**)&thunk->u1.Function;
            if (*slot == (void*)g_realCreateFileW) {
                patched += PatchIatSlot(slot, (void*)Hook_CreateFileW);
            } else if (*slot == (void*)g_realCreateFileA) {
                patched += PatchIatSlot(slot, (void*)Hook_CreateFileA);
            }
        }
    }
    return patched;
}

/* --- Inline hook for ntdll syscall stubs ---
 * Every x86 ntdll syscall stub begins with `mov eax, imm32` (B8 + 4 bytes) — a
 * deterministic 5-byte boundary. We overwrite exactly that first instruction with
 * a 5-byte E9 jmp and build a trampoline (saved 5 bytes + jmp back to stub+5). No
 * length disassembler required; if the prologue is not 0xB8 we refuse to hook. */
static BOOL InstallInlineHook(const char* name, void* hook, void** out_trampoline) {
    HMODULE hNtdll = GetModuleHandleA("ntdll.dll");
    BYTE* target;
    BYTE* tramp;
    DWORD oldp;

    if (!hNtdll) return FALSE;
    target = (BYTE*)GetProcAddress(hNtdll, name);
    if (!target) {
        Log("inline-hook: %s not found in ntdll", name);
        return FALSE;
    }
    if (target[0] != 0xB8) {
        Log("inline-hook: %s prologue not B8 (got %02X) — skipping for safety",
            name, target[0]);
        return FALSE;
    }
    tramp = (BYTE*)VirtualAlloc(NULL, 16, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!tramp) return FALSE;

    memcpy(tramp, target, 5);
    tramp[5] = 0xE9;
    *(DWORD*)(tramp + 6) = (DWORD)(target + 5) - (DWORD)(tramp + 10);

    if (!VirtualProtect(target, 5, PAGE_EXECUTE_READWRITE, &oldp)) {
        VirtualFree(tramp, 0, MEM_RELEASE);
        return FALSE;
    }
    target[0] = 0xE9;
    *(DWORD*)(target + 1) = (DWORD)hook - (DWORD)(target + 5);
    VirtualProtect(target, 5, oldp, &oldp);
    FlushInstructionCache(GetCurrentProcess(), target, 5);

    *out_trampoline = tramp;
    Log("inline-hook: %s @0x%08lX -> hook 0x%08lX (trampoline 0x%08lX)",
        name, (unsigned long)(DWORD)target, (unsigned long)(DWORD)hook,
        (unsigned long)(DWORD)tramp);
    return TRUE;
}

static void InstallHooks(void) {
    HMODULE hK32 = GetModuleHandleA("kernel32.dll");
    int iat;

    if (hK32) {
        g_realCreateFileW = (pfn_CreateFileW)GetProcAddress(hK32, "CreateFileW");
        g_realCreateFileA = (pfn_CreateFileA)GetProcAddress(hK32, "CreateFileA");
    }

    iat = 0;
    if (g_realCreateFileW || g_realCreateFileA) {
        iat = InstallIatHooks();
        Log("IAT hooks installed: %d slot(s) [CreateFileW=0x%08lX CreateFileA=0x%08lX]",
            iat, (unsigned long)(DWORD)g_realCreateFileW,
            (unsigned long)(DWORD)g_realCreateFileA);
    } else {
        Log("WARNING: could not resolve kernel32!CreateFileW/A — IAT hooks skipped");
    }

    if (InstallInlineHook("NtCreateFile", (void*)Hook_NtCreateFile, (void**)&g_realNtCreateFile)) {
        /* ok */
    }
    if (InstallInlineHook("NtOpenFile", (void*)Hook_NtOpenFile, (void**)&g_realNtOpenFile)) {
        /* ok */
    }

    g_hooksInstalled = TRUE;
    Log("asset_miss_probe armed. Watching for ERROR_FILE/PATH_NOT_FOUND + "
        "STATUS_OBJECT_NAME/PATH_NOT_FOUND (0xC0000034). Worker of interest: 0x%08X.",
        WORKER_VA);
}

/* --- DLL entry --- */

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
    (void)lpvReserved;

    if (fdwReason == DLL_PROCESS_ATTACH) {
        g_hModule = (HMODULE)hinstDLL;
        DisableThreadLibraryCalls(hinstDLL);

        LogInit();
        g_tlsGuard = TlsAlloc();
        g_exeVerified = VerifyExeSize();

        Log("============================================");
        Log("asset_miss_probe.asi loaded (PID %lu, exe_verified=%d)",
            (unsigned long)GetCurrentProcessId(), g_exeVerified);

        if (!g_exeVerified) {
            Log("REFUSING to hook: EXE size != %d bytes (expected cracked retail). "
                "VAs/worker offset would not match this binary.", EXPECTED_EXE_SIZE);
            Log("============================================");
            return TRUE;
        }

        InstallHooks();
        Log("============================================");

#ifdef ASSET_MISS_PROBE_MSGBOX
        MessageBoxA(NULL,
                    "asset_miss_probe.asi loaded.\n\n"
                    "Reproduce the GlobalEnter spin, then check the log for\n"
                    "'MISS ... path=...' lines (pmc_blackbox.log or asset_miss_probe.log).",
                    "Asset Miss Probe", MB_OK | MB_ICONINFORMATION);
#endif
    } else if (fdwReason == DLL_PROCESS_DETACH) {
        if (g_tlsGuard != TLS_OUT_OF_INDEXES) {
            TlsFree(g_tlsGuard);
            g_tlsGuard = TLS_OUT_OF_INDEXES;
        }
        if (g_fallbackLog != INVALID_HANDLE_VALUE) {
            CloseHandle(g_fallbackLog);
            g_fallbackLog = INVALID_HANDLE_VALUE;
        }
    }
    return TRUE;
}
