/**
 * density_regpresize.asi — kills the SceneObject-registry grow-storm for Mercenaries 2: WiF.
 *   (Standalone ASI, loaded by pmc_bb.dll / Ultimate ASI Loader from <game>/scripts/. Does NOT
 *    touch pmc_bb.dll or the exe on disk — MinHook detour only, per the no-byte-patch mandate.)
 *
 * THE WALL (M1 of the density-upgrade program)
 * --------------------------------------------
 * The keyed SceneObject registry (singleton @0x017c02f0) is an open-addressed, paged hash table.
 * Every entity that enters the world is inserted through FUN_0064a600. On insert it grows when
 *     count == (int)(capacity * loadfactor)     [loadfactor _DAT_00beb510 ~= 0.80]
 * and the grow policy (FUN_0064a600, cap != 0 branch) is LINEAR:
 *     new_cap = *(reg+0x10) + cap  ==  cap + 256      (page size 256)
 * Each grow reallocates the WHOLE table and re-probes every live entry (thunk_FUN_02e90000).
 * So filling to N entities costs 256+512+...+N  ==  O(N^2) rehash work. At retail density (~130k
 * with our foliage layer) that is a multi-minute freeze — the exact hang captured in the dump
 * (count 129597, cap 162048, main thread spinning in the insert/grow path).
 *
 * THE LEVER (data-only, provably safe)
 * ------------------------------------
 * The registry inits with capacity 0 (FUN_00648850). The FIRST insert therefore takes the
 * cap==0 "grow-from-empty" branch, which sizes the table to a SEPARATE field:
 *     new_cap = *(reg+0x28)  ==  DAT_017c0318   (init'd to 0x100 = 256)
 * DAT_017c0318 is written exactly ONCE in the whole binary (the init) and is read ONLY as this
 * grow-from-empty size — it is NOT used anywhere in slot addressing (addressing uses cap +0x08,
 * stride +0x0c, page-shift +0x0e, page-mask +0x10, key table +0x1c, page table +0x20). Verified
 * against output/_ghidra/mercs2_unpacked.exe_decomp.txt.
 *
 * So: make the grow-from-empty large. The first insert then allocates the entire table in ONE
 * shot (a big malloc + memset(-1) + a rehash of ZERO live entries — the identical code path as
 * the normal 0->256, only bigger). With capacity presized above peak entity count, the linear
 * cap+256 grow NEVER fires again during load. O(N^2) storm -> O(N) fill. This is a DATA change to
 * a config field (exactly what the engine itself writes), not a code splice.
 *
 * DELIVERY (covers every init/load ordering)
 * ------------------------------------------
 *  1) MinHook detour on FUN_00648850 (called once, cold, from static init @0x00a7c820): after the
 *     real init runs (setting the field to 0x100), overwrite it with PresizeCapacity. This is the
 *     reliable path — it fires no matter when init runs relative to our load.
 *  2) Belt-and-suspenders: also write the field directly at DllMain. If init already ran before
 *     we loaded (static-init before the ASI loader), the table is still EMPTY (entities register
 *     only at level load, long after boot), so setting the field now still lands before the first
 *     insert. If init runs later, it clobbers this back to 0x100 and the detour re-applies it.
 *
 * Verified target: Mercenaries2.exe / mercs2_nodrm_v3.exe, 53,482,288 bytes, imagebase 0x400000,
 * no ASLR — absolute VAs are used directly (same convention as freecam.asi/poolguard.asi).
 *
 * Config: density_regpresize.ini beside the ASI, [regpresize] PresizeCapacity=524288 (default).
 * Must be a multiple of the 256 page size; clamped to [4096, 4194304].
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include "MinHook.h"

#define EXPECTED_EXE_SIZE 53482288u

/* SceneObject keyed-registry singleton (base 0x017c02f0). */
#define REG_INIT_VA        0x00648850u   /* FUN_00648850 — void(void), the registry init */
#define REG_GROWEMPTY_ADDR 0x017c0318u   /* DAT_017c0318 — grow-from-empty size (u32), init 0x100 */

#define PAGE_SIZE          256u          /* registry +0x10; presize must be a multiple of this   */
#define PRESIZE_DEFAULT    524288u       /* 0x80000 -> ~419k-entity headroom @0.80 load (~16 MB)  */
#define PRESIZE_MIN        4096u
#define PRESIZE_MAX        4194304u      /* 0x400000 */

typedef void (*reg_init_t)(void);
static reg_init_t g_origInit = NULL;     /* MinHook trampoline (real FUN_00648850) */

static HANDLE g_log = INVALID_HANDLE_VALUE;
static DWORD  g_presize = PRESIZE_DEFAULT;
static volatile LONG g_applied = 0;

/* ---------------- logging (own file, matches freecam/poolguard style) ---------------- */
static void Log(const char *fmt, ...) {
    char buf[512]; va_list ap; int len, hl; SYSTEMTIME st;
    GetLocalTime(&st);
    hl = wsprintfA(buf, "[%02d:%02d:%02d.%03d] ", st.wHour, st.wMinute, st.wSecond, st.wMilliseconds);
    va_start(ap, fmt); len = wvsprintfA(buf + hl, fmt, ap); va_end(ap);
    if (len <= 0) return;
    len += hl;
    if (g_log != INVALID_HANDLE_VALUE) {
        DWORD w; buf[len] = '\r'; buf[len + 1] = '\n';
        WriteFile(g_log, buf, len + 2, &w, NULL); FlushFileBuffers(g_log);
    }
}

/* Overwrite the grow-from-empty size. Safe to call before OR after the real init has run. */
static void ApplyPresize(const char *when) {
    DWORD prev = *(volatile DWORD *)REG_GROWEMPTY_ADDR;
    *(volatile DWORD *)REG_GROWEMPTY_ADDR = g_presize;
    if (InterlockedExchange(&g_applied, 1) == 0)
        Log("presize APPLIED (%s): DAT_017c0318 %u -> %u  (first insert sizes the table in one shot)",
            when, (unsigned)prev, (unsigned)g_presize);
    else
        Log("presize re-applied (%s): DAT_017c0318 %u -> %u", when, (unsigned)prev, (unsigned)g_presize);
}

/* Detour of FUN_00648850. Delegate to the real init, then stamp our capacity over its 0x100. */
static void Detour_RegInit(void) {
    g_origInit();
    ApplyPresize("post-init");
}

/* ---------------- config ---------------- */
static void SidecarPath(char *out, const char *leaf) {
    char *slash;
    GetModuleFileNameA(NULL, out, MAX_PATH);          /* exe dir */
    slash = strrchr(out, '\\');
    if (slash) strcpy(slash + 1, leaf); else strcpy(out, leaf);
}
static void AsiSidecarPath(HINSTANCE self, char *out, const char *leaf) {
    char *slash;
    GetModuleFileNameA((HMODULE)self, out, MAX_PATH); /* scripts/ dir (where the ASI lives) */
    slash = strrchr(out, '\\');
    if (slash) strcpy(slash + 1, leaf); else strcpy(out, leaf);
}
static void LoadConfig(HINSTANCE self) {
    char ini[MAX_PATH];
    DWORD v;
    AsiSidecarPath(self, ini, "density_regpresize.ini");
    v = GetPrivateProfileIntA("regpresize", "PresizeCapacity", PRESIZE_DEFAULT, ini);
    if (v < PRESIZE_MIN) v = PRESIZE_MIN;
    if (v > PRESIZE_MAX) v = PRESIZE_MAX;
    v = (v + (PAGE_SIZE - 1)) & ~(PAGE_SIZE - 1);      /* round up to page multiple */
    g_presize = v;
}

/* ---------------- install ---------------- */
static BOOL VerifyExeSize(void) {
    char path[MAX_PATH]; HANDLE h; DWORD size;
    GetModuleFileNameA(NULL, path, MAX_PATH);
    h = CreateFileA(path, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
    if (h == INVALID_HANDLE_VALUE) return FALSE;
    size = GetFileSize(h, NULL); CloseHandle(h);
    return (size == EXPECTED_EXE_SIZE);
}
static void LogInit(void) {
    char path[MAX_PATH];
    SidecarPath(path, "density_regpresize.log");
    g_log = CreateFileA(path, GENERIC_WRITE, FILE_SHARE_READ, NULL,
                        CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
}

BOOL WINAPI DllMain(HINSTANCE h, DWORD reason, LPVOID r) {
    (void)r;
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(h);
        LogInit();
        LoadConfig(h);
        Log("============================================");
        Log("density_regpresize.asi loaded (PID %lu) — SceneObject registry presize = %u",
            (unsigned long)GetCurrentProcessId(), (unsigned)g_presize);
        if (!VerifyExeSize()) {
            Log("REFUSING: exe size != %u (unknown build; addresses would be wrong)", EXPECTED_EXE_SIZE);
            return TRUE;
        }
        if (MH_Initialize() != MH_OK) { Log("MH_Initialize failed"); return TRUE; }
        if (MH_CreateHook((LPVOID)(DWORD_PTR)REG_INIT_VA, (LPVOID)Detour_RegInit,
                          (void **)&g_origInit) != MH_OK ||
            MH_EnableHook((LPVOID)(DWORD_PTR)REG_INIT_VA) != MH_OK) {
            Log("hook FUN_00648850 FAILED — presize not armed via init path");
        } else {
            Log("hook armed: FUN_00648850 @0x%08X (registry init).", REG_INIT_VA);
        }
        /* Fallback: if init already ran (static-init before us) the table is still empty. */
        ApplyPresize("dllmain");
        Log("first SceneObject insert will size the table to %u in one allocation — no grow storm.",
            (unsigned)g_presize);
        Log("============================================");
    } else if (reason == DLL_PROCESS_DETACH) {
        if (g_log != INVALID_HANDLE_VALUE) CloseHandle(g_log);
    }
    return TRUE;
}
