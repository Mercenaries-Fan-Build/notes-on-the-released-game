/**
 * shader_accept_probe.asi — R0 of the density-upgrade M4 live proof.
 *
 * QUESTION: does the REAL dxwrapper D3D9 runtime accept our instancing-spliced vs_3_0 bytecode?
 * Offline (`shaderforge`) we proved the 60 static-mesh VS splice + re-parse cleanly; this ASI is the
 * first real-driver gate: for every target it calls the engine's own IDirect3DDevice9::CreateVertexShader
 * on BOTH the untouched blob (control) and the spliced blob, and logs the two HRESULTs. It draws
 * NOTHING and changes NO render state — pure create+release — so there is no wedge risk on the frame.
 *
 * DEVICE ACCESS (from the shader loader FUN_0085b3f0):
 *   the engine issues CreateVertexShader as  (*(void***)dev)[91]  where 0x16c/4 = 91, and dev is
 *   reached via  PTR_PTR_00dfc2fc + 0x2d28.  The decomp is ambiguous about whether the symbol is the
 *   VALUE at 0x00dfc2fc or the address itself, so we try BOTH interpretations, validate that the
 *   candidate's vtable[91] lands in committed executable memory, and CONFIRM by test-creating a
 *   known-good ORIGINAL blob (a real device returns S_OK) before trusting it.
 *
 * The bundle `shader_accept_probe_bundle.bin` (emitted by `shaderforge bundle`) sits beside the ASI.
 * Verified target exe = 53,482,288 bytes, imagebase 0x400000, no ASLR (absolute VAs used directly).
 * Runs once as soon as a device confirms; press F10 to re-run (e.g. after you are fully in-world).
 * Writes shader_accept_probe.log next to the exe.
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <string.h>

#define EXPECTED_EXE_SIZE 53482288u
#define VA_DEV_PTRPTR     0x00dfc2fcu   /* PTR_PTR_00dfc2fc */
#define DEV_OFFSET        0x2d28u
#define VTBL_CREATE_VS    91u           /* 0x16c / 4 — IDirect3DDevice9::CreateVertexShader */
#define VTBL_RELEASE      2u            /* IUnknown::Release */

typedef long  (__stdcall *CreateVS_t)(void *thisptr, const void *func, void **out);
typedef ULONG (__stdcall *Release_t)(void *thisptr);

static HANDLE g_log = INVALID_HANDLE_VALUE;
static HINSTANCE g_self;

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

static BOOL Readable(const void *p, SIZE_T n) {
    MEMORY_BASIC_INFORMATION mbi;
    if (!p) return FALSE;
    if (!VirtualQuery(p, &mbi, sizeof(mbi))) return FALSE;
    if (mbi.State != MEM_COMMIT) return FALSE;
    if (mbi.Protect & (PAGE_NOACCESS | PAGE_GUARD)) return FALSE;
    /* n bytes must stay inside this committed region */
    return ((const char *)p + n) <= ((const char *)mbi.BaseAddress + mbi.RegionSize);
}
static BOOL Executable(const void *p) {
    MEMORY_BASIC_INFORMATION mbi;
    if (!p || !VirtualQuery(p, &mbi, sizeof(mbi))) return FALSE;
    if (mbi.State != MEM_COMMIT) return FALSE;
    return (mbi.Protect & (PAGE_EXECUTE | PAGE_EXECUTE_READ | PAGE_EXECUTE_READWRITE
                           | PAGE_EXECUTE_WRITECOPY)) != 0;
}
/* A real IDirect3DDevice9 vtable lives in the D3D runtime DLL (dxwrapper/d3d9), never in the game
 * exe. Reject any candidate whose vtable's allocation base is the exe module — kills the crash risk
 * from the wrong device-pointer interpretation dereferencing a game-side field. */
static BOOL VtblInRuntimeDll(const void *vtbl) {
    MEMORY_BASIC_INFORMATION mbi;
    void *exeBase = (void *)GetModuleHandleA(NULL);
    if (!VirtualQuery(vtbl, &mbi, sizeof(mbi))) return FALSE;
    return mbi.AllocationBase != NULL && mbi.AllocationBase != exeBase;
}

/* Return a candidate IDirect3DDevice9* whose vtbl[91] is executable, or NULL. */
static void *ResolveDeviceCandidate(int interp) {
    void *thisptr = NULL, **vtbl;
    if (interp == 0) {
        /* symbol == value stored at 0x00dfc2fc */
        void *p = *(void **)VA_DEV_PTRPTR;
        if (!Readable(p, DEV_OFFSET + 4)) return NULL;
        thisptr = *(void **)((char *)p + DEV_OFFSET);
    } else {
        /* symbol == the address 0x00dfc2fc itself */
        void *slot = (void *)(VA_DEV_PTRPTR + DEV_OFFSET);
        if (!Readable(slot, 4)) return NULL;
        thisptr = *(void **)slot;
    }
    if (!Readable(thisptr, 4)) return NULL;
    vtbl = *(void ***)thisptr;
    if (!Readable(vtbl, (VTBL_CREATE_VS + 1) * sizeof(void *))) return NULL;
    if (!VtblInRuntimeDll(vtbl)) return NULL;
    if (!Executable(vtbl[VTBL_CREATE_VS])) return NULL;
    return thisptr;
}

/* ---------------- bundle ---------------- */
static unsigned char *g_bundle = NULL;
static DWORD g_bundleLen = 0;

static void AsiSidecar(char *out, const char *leaf) {
    char *slash;
    GetModuleFileNameA((HMODULE)g_self, out, MAX_PATH);
    slash = strrchr(out, '\\');
    if (slash) strcpy(slash + 1, leaf); else strcpy(out, leaf);
}
static BOOL LoadBundle(void) {
    char path[MAX_PATH]; HANDLE h; DWORD sz, rd;
    AsiSidecar(path, "shader_accept_probe_bundle.bin");
    h = CreateFileA(path, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
    if (h == INVALID_HANDLE_VALUE) { Log("bundle not found: %s", path); return FALSE; }
    if (g_bundle) { VirtualFree(g_bundle, 0, MEM_RELEASE); g_bundle = NULL; }  /* reload support */
    sz = GetFileSize(h, NULL);
    g_bundle = (unsigned char *)VirtualAlloc(NULL, sz, MEM_COMMIT, PAGE_READWRITE);
    if (!g_bundle) { CloseHandle(h); return FALSE; }
    if (!ReadFile(h, g_bundle, sz, &rd, NULL) || rd != sz) { CloseHandle(h); return FALSE; }
    CloseHandle(h);
    g_bundleLen = sz;
    if (sz < 12 || memcmp(g_bundle, "R0SB", 4) != 0) { Log("bad bundle magic"); return FALSE; }
    Log("bundle loaded: %s (%lu bytes, %u entries)", path, (unsigned long)sz,
        *(DWORD *)(g_bundle + 8));
    return TRUE;
}

static DWORD rd32(DWORD off) { return *(DWORD *)(g_bundle + off); }

/* Run every entry through CreateVertexShader on `dev`. */
static void RunTest(void *dev) {
    CreateVS_t create = (CreateVS_t)((void **)*(void ***)dev)[VTBL_CREATE_VS];
    DWORD count = rd32(8), off = 12, i;
    int origOK = 0, splOK = 0, origFail = 0, splFail = 0;
    Log("---- CreateVertexShader test on device %p (%u entries) ----", dev, (unsigned)count);
    for (i = 0; i < count; i++) {
        DWORD id      = rd32(off);
        WORD  odreg   = *(WORD *)(g_bundle + off + 4);
        WORD  wregs   = *(WORD *)(g_bundle + off + 6);
        BYTE  ibase   = g_bundle[off + 8];
        DWORD origLen = rd32(off + 12);
        DWORD splLen  = rd32(off + 16);
        unsigned char *orig = g_bundle + off + 20;
        unsigned char *spl  = orig + origLen;
        void *vs = NULL; long hrO, hrS;

        hrO = create(dev, orig, &vs);
        if (hrO >= 0 && vs) { origOK++; ((Release_t)((void **)*(void ***)vs)[VTBL_RELEASE])(vs); }
        else origFail++;
        vs = NULL;
        hrS = create(dev, spl, &vs);
        if (hrS >= 0 && vs) { splOK++; ((Release_t)((void **)*(void ***)vs)[VTBL_RELEASE])(vs); }
        else splFail++;

        if (hrO < 0 || hrS < 0)
            Log("  id=0x%08X objData@c%u(%ux4) v%u : orig hr=0x%08lX  spliced hr=0x%08lX",
                (unsigned)id, (unsigned)odreg, (unsigned)wregs, (unsigned)ibase,
                (unsigned long)hrO, (unsigned long)hrS);

        off += 20 + origLen + splLen;
        off = (off + 3) & ~3u;
    }
    Log("==== RESULT: original %d/%u OK, spliced %d/%u OK (orig fail %d, spliced fail %d) ====",
        origOK, (unsigned)count, splOK, (unsigned)count, origFail, splFail);
    if (splFail == 0 && splOK == (int)count)
        Log("==== R0 PASS: the real dxwrapper D3D9 runtime accepts ALL %u spliced vs_3_0. ====",
            (unsigned)count);
    else
        Log("==== R0 PARTIAL/FAIL: %d spliced shaders rejected by the driver. ====", splFail);
}

/* Confirm a candidate device by test-creating the FIRST original blob (real device -> S_OK). */
static void *ConfirmDevice(void) {
    int interp;
    for (interp = 0; interp < 2; interp++) {
        void *dev = ResolveDeviceCandidate(interp);
        if (!dev) continue;
        CreateVS_t create = (CreateVS_t)((void **)*(void ***)dev)[VTBL_CREATE_VS];
        unsigned char *orig = g_bundle + 12 + 20;   /* first entry's original blob */
        void *vs = NULL;
        long hr = create(dev, orig, &vs);
        if (hr >= 0 && vs) {
            ((Release_t)((void **)*(void ***)vs)[VTBL_RELEASE])(vs);
            Log("device confirmed via interp %d: %p (control blob created S_OK)", interp, dev);
            return dev;
        }
        Log("candidate interp %d (%p) rejected control blob hr=0x%08lX — not the device",
            interp, dev, (unsigned long)hr);
    }
    return NULL;
}

static DWORD WINAPI Worker(LPVOID arg) {
    int waited = 0; void *dev = NULL; BOOL ranOnce = FALSE;
    (void)arg;
    if (!LoadBundle()) { Log("no bundle — aborting"); return 0; }
    /* poll up to ~60s for the device to exist */
    while (waited < 240) {
        dev = ConfirmDevice();
        if (dev) break;
        Sleep(250); waited++;
    }
    if (!dev) { Log("device never confirmed within timeout — is a 3D view up?"); }
    else { RunTest(dev); ranOnce = TRUE; }
    /* F10 re-run (e.g. once fully in-world) */
    for (;;) {
        if (GetAsyncKeyState(VK_F10) & 1) {
            Log("F10: reloading bundle + re-running");
            if (LoadBundle()) {
                dev = ConfirmDevice();
                if (dev) RunTest(dev);
                else Log("F10: device not available");
            }
        }
        Sleep(100);
        (void)ranOnce;
    }
}

static void LogInit(void) {
    char path[MAX_PATH], *slash;
    GetModuleFileNameA(NULL, path, MAX_PATH);
    slash = strrchr(path, '\\');
    if (slash) strcpy(slash + 1, "shader_accept_probe.log"); else strcpy(path, "shader_accept_probe.log");
    g_log = CreateFileA(path, GENERIC_WRITE, FILE_SHARE_READ, NULL,
                        CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
}
static BOOL VerifyExeSize(void) {
    char path[MAX_PATH]; HANDLE h; DWORD size;
    GetModuleFileNameA(NULL, path, MAX_PATH);
    h = CreateFileA(path, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
    if (h == INVALID_HANDLE_VALUE) return FALSE;
    size = GetFileSize(h, NULL); CloseHandle(h);
    return (size == EXPECTED_EXE_SIZE);
}

BOOL WINAPI DllMain(HINSTANCE h, DWORD reason, LPVOID r) {
    (void)r;
    if (reason == DLL_PROCESS_ATTACH) {
        g_self = h;
        DisableThreadLibraryCalls(h);
        LogInit();
        Log("============================================");
        Log("shader_accept_probe.asi loaded (PID %lu) — R0 CreateVertexShader gate",
            (unsigned long)GetCurrentProcessId());
        if (!VerifyExeSize()) {
            Log("REFUSING: exe size != %u (unknown build; device VAs would be wrong)", EXPECTED_EXE_SIZE);
            return TRUE;
        }
        CreateThread(NULL, 0, Worker, NULL, 0, NULL);
    } else if (reason == DLL_PROCESS_DETACH) {
        if (g_log != INVALID_HANDLE_VALUE) CloseHandle(g_log);
    }
    return TRUE;
}
