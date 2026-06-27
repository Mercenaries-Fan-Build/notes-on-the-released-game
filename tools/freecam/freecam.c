/**
 * freecam.asi — standalone freecam ASI plugin for Mercenaries 2: World in Flames.
 *   (Does NOT touch pmc_bb.dll. Loaded by the ASI loader from <game>/scripts/.)
 *
 * F11 toggles a detached free-flying camera; F11 again restores the follow-cam.
 *
 * Input: GetAsyncKeyState, WH_KEYBOARD_LL, and raw input all "succeed" but deliver nothing — the
 * .securom DRM fakes/blocks the OS input APIs. So we hook the game's OWN DirectInput keyboard read,
 * IDirectInputDevice8::GetDeviceState (inline MinHook — which DOES work here), reading exactly what
 * the game reads. Keys are DIK_* scan codes; g_keys[] is indexed by DIK.
 *   Chain: hook DirectInput8Create -> IDirectInput8::CreateDevice(vt[3]) -> IDirectInputDevice8::
 *          GetDeviceState(vt[9]). The keyboard state is the 256-byte (cbData==256) buffer.
 *
 * Camera (verified vs DEPLOYED Mercenaries2.exe, 53,482,288 bytes, imagebase 0x400000, no ASLR):
 *   view = *(void**)0x00DFC2F8 ; idx = *(u16*)(view+0x2B92) ; cam = view + idx*0xE80
 *   cam+0x10  = source transform (4x4) the matrix-builder reads -> overriding it moves the camera
 *   cam+0xB20 = camera world position (x,y,z), confirmed output
 *   hook FUN_0085A9E0 @0x0085A9E0 (per-view; calls builder with cam+0x10)
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "MinHook.h"

#define EXPECTED_EXE_SIZE 53482288
#define VIEW_PTR     0x00DFC2F8
#define VIEW_IDX_OFF 0x2B92
#define VIEW_STRIDE  0xE80
#define CAM_SRC_OFF  0x10
#define CAM_POS_OFF  0xB20
#define HOOK_VA      0x0085A9E0

#define DIK_F11 0x57

void *g_origView = NULL;                 /* MinHook trampoline (non-static: asm references it) */

static HANDLE    g_log   = INVALID_HANDLE_VALUE;
static BOOL      g_exeOk = FALSE;

static volatile LONG g_freecam     = 0;
static volatile LONG g_needCapture = 0;
static volatile LONG g_logged      = 0;
static float         g_mat[16];
static CRITICAL_SECTION g_lock;
static volatile char g_keys[256];        /* live key state (DIK-indexed) from GetDeviceState */

/* ---------------- logging (own file) ---------------- */
static void Log(const char *fmt, ...) {
    char buf[700]; va_list ap; int len, hl; SYSTEMTIME st;
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

static DWORD GetCam(void) {
    DWORD view = *(volatile DWORD *)VIEW_PTR;
    if (view < 0x10000 || view >= 0x80000000) return 0;
    WORD idx = *(volatile WORD *)(view + VIEW_IDX_OFF);
    if (idx > 8) return 0;
    return view + (DWORD)idx * VIEW_STRIDE;
}

void __cdecl FreecamTick(DWORD *stk) {
    /* probe once, the first time freecam is ON (user in gameplay): which register/arg holds the live
     * camera? stk after `pushal`: [0]=EDI [1]=ESI [2]=EBP [3]=ESP [4]=EBX [5]=EDX [6]=ECX [7]=EAX;
     * [8]=retaddr, [9..]=stack args. A real camera has a sensible +0xB20 position + ~unit +0xAB0 view. */
    static volatile LONG probed = 0;
    if (g_freecam && InterlockedExchange(&probed, 1) == 0) {
        DWORD cand[8] = { stk[0], stk[1], stk[2], stk[4], stk[9], stk[10], stk[11], stk[12] };
        const char *nm[8] = { "EDI", "ESI", "EBP", "EBX", "arg0", "arg1", "arg2", "arg3" };
        int i;
        Log("PROBE (freecam just turned on):");
        for (i = 0; i < 8; i++) {
            DWORD c = cand[i];
            if (c >= 0x10000 && c < 0x7F000000 && !IsBadReadPtr((void *)c, 0xB30)) {
                DWORD *q = (DWORD *)c;
                Log("  %-4s=%08X  +B20pos=[%08X %08X %08X]  +AB0view=[%08X %08X %08X %08X]",
                    nm[i], c, q[0xB20 / 4], q[0xB24 / 4], q[0xB28 / 4],
                    q[0xAB0 / 4], q[0xAB4 / 4], q[0xAB8 / 4], q[0xABC / 4]);
            } else Log("  %-4s=%08X  (invalid/unreadable)", nm[i], c);
        }
    }
    if (!g_freecam) return;
    DWORD cam = GetCam();
    if (!cam) return;
    float *src = (float *)(cam + CAM_SRC_OFF);

    if (g_needCapture) {
        EnterCriticalSection(&g_lock);
        memcpy(g_mat, src, 64);
        g_needCapture = 0;
        LeaveCriticalSection(&g_lock);
        if (!g_logged) {
            g_logged = 1;
            DWORD *s = (DWORD *)g_mat, *p = (DWORD *)(cam + CAM_POS_OFF);
            Log("CAPTURE cam=%08X", cam);
            Log("  src+0x10 row0=[%08X %08X %08X %08X]", s[0], s[1], s[2], s[3]);
            Log("  src+0x10 row1=[%08X %08X %08X %08X]", s[4], s[5], s[6], s[7]);
            Log("  src+0x10 row2=[%08X %08X %08X %08X]", s[8], s[9], s[10], s[11]);
            Log("  src+0x10 row3=[%08X %08X %08X %08X]", s[12], s[13], s[14], s[15]);
            Log("  cam+0xB20 pos=[%08X %08X %08X]  (these 3 = position row, find them above)", p[0], p[1], p[2]);
        }
    }
    EnterCriticalSection(&g_lock);
    memcpy(src, g_mat, 64);   /* freeze */
    LeaveCriticalSection(&g_lock);
}

__attribute__((naked, used))
void Detour_View(void) {
    __asm__ (
        "pushal\n\t"
        "pushl %esp\n\t"          /* arg = post-pushal stack snapshot (regs + args) */
        "call _FreecamTick\n\t"
        "addl $4, %esp\n\t"
        "popal\n\t"
        "jmp *_g_origView\n\t"
    );
}

/* ---------------- input: hook the game's DirectInput keyboard read ---------------- */
typedef HRESULT (WINAPI   *DI8Create_t)(HINSTANCE, DWORD, const void *, void **, void *);
typedef HRESULT (__stdcall *CreateDevice_t)(void *, const void *, void **, void *);
typedef HRESULT (__stdcall *GetDeviceState_t)(void *, DWORD, void *);
static DI8Create_t      g_origDI8Create      = NULL;
static CreateDevice_t   g_origCreateDevice   = NULL;
static GetDeviceState_t g_origGetDeviceState = NULL;

static HRESULT __stdcall Hook_GetDeviceState(void *This, DWORD cb, void *data) {
    HRESULT hr = g_origGetDeviceState(This, cb, data);
    if (hr == 0 /*DI_OK*/ && cb == 256 && data) {
        static volatile LONG seen = 0, cnt = 0;
        const BYTE *st = (const BYTE *)data;
        if (InterlockedExchange(&seen, 1) == 0) Log("GetDeviceState keyboard poll live (cb=256)");
        int f11 = (st[DIK_F11] & 0x80) != 0;
        if (f11 && !g_keys[DIK_F11]) {   /* rising edge */
            if (!g_freecam) { g_needCapture = 1; g_freecam = 1; g_logged = 0; Log("FREECAM ON"); }
            else            { g_freecam = 0; Log("FREECAM OFF"); }
        }
        int i;
        for (i = 0; i < 256; i++) g_keys[i] = (st[i] & 0x80) ? 1 : 0;
        if ((InterlockedIncrement(&cnt) % 180) == 0)
            Log("GetDeviceState alive: f11(DIK57)=%d freecam=%d", g_keys[DIK_F11], (int)g_freecam);
    }
    return hr;
}

static HRESULT __stdcall Hook_CreateDevice(void *This, const void *rguid, void **dev, void *outer) {
    HRESULT hr = g_origCreateDevice(This, rguid, dev, outer);
    static volatile LONG hooked = 0;
    if (hr == 0 && dev && *dev && InterlockedExchange(&hooked, 1) == 0) {
        void **vt = *(void ***)(*dev);
        Log("CreateDevice -> device=%p; hooking GetDeviceState @vt[9]=%p", *dev, vt[9]);
        if (MH_CreateHook(vt[9], (void *)Hook_GetDeviceState, (void **)&g_origGetDeviceState) == MH_OK)
            MH_EnableHook(vt[9]);
        else Log("  MH_CreateHook(GetDeviceState) FAILED");
    }
    return hr;
}

static HRESULT WINAPI Hook_DI8Create(HINSTANCE hi, DWORD ver, const void *iid, void **out, void *outer) {
    HRESULT hr = g_origDI8Create(hi, ver, iid, out, outer);
    static volatile LONG hooked = 0;
    if (hr == 0 && out && *out && InterlockedExchange(&hooked, 1) == 0) {
        void **vt = *(void ***)(*out);
        Log("DirectInput8Create -> di8=%p; hooking CreateDevice @vt[3]=%p", *out, vt[3]);
        if (MH_CreateHook(vt[3], (void *)Hook_CreateDevice, (void **)&g_origCreateDevice) == MH_OK)
            MH_EnableHook(vt[3]);
        else Log("  MH_CreateHook(CreateDevice) FAILED");
    }
    return hr;
}

static void InstallInputHook(void) {
    HMODULE di = GetModuleHandleA("dinput8.dll");
    if (!di) di = LoadLibraryA("dinput8.dll");
    if (!di) { Log("dinput8.dll not available — input hook NOT installed"); return; }
    void *create = (void *)GetProcAddress(di, "DirectInput8Create");
    if (!create) { Log("DirectInput8Create not found"); return; }
    if (MH_CreateHook(create, (void *)Hook_DI8Create, (void **)&g_origDI8Create) == MH_OK &&
        MH_EnableHook(create) == MH_OK)
        Log("hook armed: DirectInput8Create @%p (dinput8.dll) — waiting for keyboard device", create);
    else
        Log("MH_CreateHook(DirectInput8Create) FAILED");
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
    char path[MAX_PATH], *slash;
    GetModuleFileNameA(NULL, path, MAX_PATH);
    slash = strrchr(path, '\\');
    if (slash) strcpy(slash + 1, "freecam.log"); else strcpy(path, "freecam.log");
    g_log = CreateFileA(path, GENERIC_WRITE, FILE_SHARE_READ, NULL,
                        CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
}

BOOL WINAPI DllMain(HINSTANCE h, DWORD reason, LPVOID r) {
    (void)r;
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(h);
        InitializeCriticalSection(&g_lock);
        LogInit();
        g_exeOk = VerifyExeSize();
        Log("============================================");
        Log("freecam.asi loaded (PID %lu, exe_ok=%d) — F11 toggles freecam (DirectInput hook)",
            (unsigned long)GetCurrentProcessId(), g_exeOk);
        if (!g_exeOk) { Log("REFUSING: exe size != %d", EXPECTED_EXE_SIZE); return TRUE; }
        if (MH_Initialize() != MH_OK) { Log("MH_Initialize failed"); return TRUE; }
        if (MH_CreateHook((LPVOID)(DWORD_PTR)HOOK_VA, (LPVOID)Detour_View, (void **)&g_origView) != MH_OK ||
            MH_EnableHook((LPVOID)(DWORD_PTR)HOOK_VA) != MH_OK) {
            Log("hook FUN_0085A9E0 FAILED"); return TRUE;
        }
        Log("hook armed: FUN_0085A9E0 @0x%08X (camera).", HOOK_VA);
        InstallInputHook();
        Log("Press F11 in-game to capture+freeze the camera.");
        Log("============================================");
    } else if (reason == DLL_PROCESS_DETACH) {
        if (g_log != INVALID_HANDLE_VALUE) CloseHandle(g_log);
    }
    return TRUE;
}
