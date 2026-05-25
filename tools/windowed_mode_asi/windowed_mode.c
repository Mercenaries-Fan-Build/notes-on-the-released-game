/**
 * windowed_mode.asi — Forces D3D9 Windowed Mode for Mercenaries 2: World in Flames
 *
 * Hooks IDirect3D9::CreateDevice via vtable patching to force windowed mode.
 * Minimum resolution enforced: 1280x720. Window style set to WS_OVERLAPPEDWINDOW.
 *
 * Build: make mingw  (cross-compile with MinGW)
 * Install: Copy windowed_mode.asi to <game>/scripts/
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <stdarg.h>

/* --- Logging --- */

static HMODULE g_hModule = NULL;
static HANDLE  g_logFile = INVALID_HANDLE_VALUE;

static void LogInit(void) {
    char path[MAX_PATH];
    char *dot;

    GetModuleFileNameA(g_hModule, path, MAX_PATH);
    dot = strrchr(path, '.');
    if (dot) strcpy(dot, ".log");
    else strcat(path, ".log");

    g_logFile = CreateFileA(path, GENERIC_WRITE, FILE_SHARE_READ,
                            NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
}

static void Log(const char *fmt, ...) {
    char buf[1024];
    int len;
    va_list ap;
    DWORD written;

    va_start(ap, fmt);
    len = wvsprintfA(buf, fmt, ap);
    va_end(ap);

    if (len <= 0) return;

    if (g_logFile != INVALID_HANDLE_VALUE) {
        buf[len] = '\r';
        buf[len + 1] = '\n';
        WriteFile(g_logFile, buf, len + 2, &written, NULL);
        FlushFileBuffers(g_logFile);
    }
}

static void LogClose(void) {
    if (g_logFile != INVALID_HANDLE_VALUE) {
        CloseHandle(g_logFile);
        g_logFile = INVALID_HANDLE_VALUE;
    }
}

/* --- D3D9 Types --- */

typedef void* IDirect3D9;
typedef void* IDirect3DDevice9;

typedef struct {
    UINT  BackBufferWidth;
    UINT  BackBufferHeight;
    UINT  BackBufferFormat;
    UINT  BackBufferCount;
    UINT  MultiSampleType;
    DWORD MultiSampleQuality;
    UINT  SwapEffect;
    HWND  hDeviceWindow;
    BOOL  Windowed;
    BOOL  EnableAutoDepthStencil;
    UINT  AutoDepthStencilFormat;
    DWORD Flags;
    UINT  FullScreen_RefreshRateInHz;
    UINT  PresentationInterval;
} D3DPRESENT_PARAMETERS_PARTIAL;

/* --- CreateDevice Hook --- */

static DWORD g_origCreateDevice = 0;

typedef HRESULT (__stdcall *CreateDevice_t)(
    void* pThis, UINT Adapter, UINT DeviceType, HWND hFocusWindow,
    DWORD BehaviorFlags, D3DPRESENT_PARAMETERS_PARTIAL* pPP, IDirect3DDevice9** ppDevice);

static HRESULT __stdcall Hook_CreateDevice(
    void* pThis, UINT Adapter, UINT DeviceType, HWND hFocusWindow,
    DWORD BehaviorFlags, D3DPRESENT_PARAMETERS_PARTIAL* pPP, IDirect3DDevice9** ppDevice)
{
    if (pPP && !pPP->Windowed) {
        Log("[WINDOWED] Forcing windowed mode (%ux%u)", pPP->BackBufferWidth, pPP->BackBufferHeight);
        pPP->Windowed = TRUE;
        if (pPP->BackBufferWidth < 1280) pPP->BackBufferWidth = 1280;
        if (pPP->BackBufferHeight < 720) pPP->BackBufferHeight = 720;
        pPP->FullScreen_RefreshRateInHz = 0;
        pPP->BackBufferFormat = 0; /* D3DFMT_UNKNOWN — use desktop format */
        if (pPP->SwapEffect == 2) /* D3DSWAPEFFECT_FLIP not valid windowed */
            pPP->SwapEffect = 1;  /* D3DSWAPEFFECT_DISCARD */
    }

    CreateDevice_t orig = (CreateDevice_t)g_origCreateDevice;
    HRESULT hr = orig(pThis, Adapter, DeviceType, hFocusWindow, BehaviorFlags, pPP, ppDevice);

    if (hr == 0 && hFocusWindow) {
        SetWindowLongA(hFocusWindow, -16 /*GWL_STYLE*/,
            0x00CF0000 /*WS_OVERLAPPEDWINDOW*/ | 0x10000000 /*WS_VISIBLE*/);
        SetWindowPos(hFocusWindow, NULL, 50, 50,
            pPP->BackBufferWidth + 16, pPP->BackBufferHeight + 39,
            0x0020 /*SWP_FRAMECHANGED*/);
    }
    return hr;
}

/* --- Hook Installation --- */

static void InstallD3D9WindowedHook(void) {
    HMODULE hD3D9 = GetModuleHandleA("d3d9.dll");
    if (!hD3D9) {
        hD3D9 = LoadLibraryA("d3d9.dll");
    }
    if (!hD3D9) {
        Log("[WINDOWED] d3d9.dll not found — skip");
        return;
    }

    typedef IDirect3D9* (__stdcall *Direct3DCreate9_t)(UINT);
    Direct3DCreate9_t pCreate = (Direct3DCreate9_t)GetProcAddress(hD3D9, "Direct3DCreate9");
    if (!pCreate) {
        Log("[WINDOWED] Direct3DCreate9 not found");
        return;
    }

    IDirect3D9* pD3D = pCreate(32 /* D3D_SDK_VERSION */);
    if (!pD3D) {
        Log("[WINDOWED] Direct3DCreate9 returned NULL");
        return;
    }

    /* vtable[16] = CreateDevice for IDirect3D9 */
    DWORD* vtable = *(DWORD**)pD3D;
    DWORD* pCreateDeviceSlot = &vtable[16];

    DWORD oldProtect;
    if (VirtualProtect(pCreateDeviceSlot, 4, PAGE_READWRITE, &oldProtect)) {
        g_origCreateDevice = *pCreateDeviceSlot;
        *pCreateDeviceSlot = (DWORD)Hook_CreateDevice;
        VirtualProtect(pCreateDeviceSlot, 4, oldProtect, &oldProtect);
        Log("[WINDOWED] CreateDevice vtable hooked (orig=0x%08X)", g_origCreateDevice);
    } else {
        Log("[WINDOWED] VirtualProtect failed on vtable");
    }

    /* Release the temporary D3D object (Release = vtable[2]) */
    typedef ULONG (__stdcall *Release_t)(void*);
    Release_t pRelease = (Release_t)vtable[2];
    pRelease(pD3D);
}

/* --- DLL Entry Point --- */

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
    (void)lpvReserved;

    if (fdwReason == DLL_PROCESS_ATTACH) {
        g_hModule = (HMODULE)hinstDLL;
        DisableThreadLibraryCalls(hinstDLL);

        LogInit();
        Log("windowed_mode.asi loaded (PID %d)", GetCurrentProcessId());

        InstallD3D9WindowedHook();

        Log("D3D9 windowed mode hook installed");
    } else if (fdwReason == DLL_PROCESS_DETACH) {
        Log("windowed_mode.asi unloaded");
        LogClose();
    }
    return TRUE;
}
