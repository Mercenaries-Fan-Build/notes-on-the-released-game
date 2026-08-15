/**
 * density_instance_probe.asi — R1 of the density-upgrade M4: prove HW instancing works IN THE REAL
 * ENGINE using our R0-verified instancing-spliced vs_3_0.
 *
 * It hooks the device's Present and, each frame, issues ONE instanced DrawIndexedPrimitive that draws
 * a small cube N times via a per-instance vertex stream (stream 1 = the World matrix rows), bound to
 * the spliced PgMesh VS (which reads World from those inputs instead of constants) + a trivial magenta
 * PS. viewContextData (the shader's ViewProj, c0..c3) is set to IDENTITY and the per-instance World
 * matrices place the cubes directly in clip space — so the grid is visible regardless of the game
 * camera, with no dependence on reading engine internals. If a 4x4 grid of magenta cubes appears from
 * a SINGLE instanced draw, the whole instancing path is proven live (spliced VS + instance buffer +
 * SetStreamSourceFreq + one instanced DIP). Snip the screen for the visual; the log records the draw.
 *
 * Safe by construction: Present is a per-frame (warm) call, not the per-primitive hot path; all state
 * is saved/restored with a D3D state block; the hook fails open (just calls the original Present) if
 * anything is not ready. Device via the R0-proven global (PTR_PTR_00dfc2fc + 0x2d28). No d3d9/d3dx/
 * version imports — only COM vtable calls on the engine's device (lesson from the version.dll break).
 * Kill switch: env DENSITY_INSTANCE_PROBE=0. Writes density_instance_probe.log next to the exe.
 */
#define WIN32_LEAN_AND_MEAN
#define COBJMACROS
#include <windows.h>
#include <d3d9.h>
#include "spliced_vs.h"   /* g_splicedVS[520] — rec419 (PgMesh) instancing-spliced */

#define VA_DEV_PTRPTR 0x00dfc2fcu
#define DEV_OFFSET    0x2d28u
#define GRID          4              /* 4x4 = 16 instances */
#define NUM_INST      (GRID * GRID)

/* trivial ps_3_0: def c0=(1,0,1,1); mov oC0,c0  — solid magenta */
static const DWORD g_ps[] = {
    0xFFFF0300, 0x05000051, 0xA00F0000,
    0x3F800000, 0x00000000, 0x3F800000, 0x3F800000,
    0x02000001, 0x800F0800, 0xA0E40000, 0x0000FFFF,
};

typedef HRESULT (WINAPI *PresentFn)(IDirect3DDevice9 *, const RECT *, const RECT *, HWND, const RGNDATA *);

static HANDLE g_log = INVALID_HANDLE_VALUE;
static PresentFn g_origPresent = NULL;
static IDirect3DDevice9 *g_dev = NULL;
static IDirect3DVertexShader9 *g_vs = NULL;
static IDirect3DPixelShader9  *g_ps_obj = NULL;
static IDirect3DVertexBuffer9 *g_cubeVB = NULL, *g_instVB = NULL;
static IDirect3DIndexBuffer9  *g_cubeIB = NULL;
static IDirect3DVertexDeclaration9 *g_decl = NULL;
static int g_res_ok = 0, g_res_tried = 0, g_disabled = 0, g_logged_draw = 0;

static void Log(const char *fmt, ...) {
    char buf[512]; va_list ap; int len, hl; SYSTEMTIME st;
    GetLocalTime(&st);
    hl = wsprintfA(buf, "[%02d:%02d:%02d.%03d] ", st.wHour, st.wMinute, st.wSecond, st.wMilliseconds);
    va_start(ap, fmt); len = wvsprintfA(buf + hl, fmt, ap); va_end(ap);
    if (len <= 0) return; len += hl;
    if (g_log != INVALID_HANDLE_VALUE) { DWORD w; buf[len]='\r'; buf[len+1]='\n';
        WriteFile(g_log, buf, len+2, &w, NULL); FlushFileBuffers(g_log); }
}

/* --- device resolution (R0-proven) --- */
static BOOL Readable(const void *p, SIZE_T n) {
    MEMORY_BASIC_INFORMATION mbi;
    if (!p || !VirtualQuery(p, &mbi, sizeof(mbi))) return FALSE;
    if (mbi.State != MEM_COMMIT || (mbi.Protect & (PAGE_NOACCESS | PAGE_GUARD))) return FALSE;
    return ((const char *)p + n) <= ((const char *)mbi.BaseAddress + mbi.RegionSize);
}
static IDirect3DDevice9 *ResolveDevice(void) {
    void *p = *(void **)VA_DEV_PTRPTR;
    if (!Readable(p, DEV_OFFSET + 4)) return NULL;
    void *dev = *(void **)((char *)p + DEV_OFFSET);
    if (!Readable(dev, 4)) return NULL;
    void **vtbl = *(void ***)dev;
    if (!Readable(vtbl, 20 * sizeof(void *))) return NULL;   /* need up to Present(17) */
    /* vtbl must live in a runtime DLL, not the exe */
    MEMORY_BASIC_INFORMATION mbi;
    if (!VirtualQuery(vtbl, &mbi, sizeof(mbi))) return NULL;
    if (mbi.AllocationBase == (void *)GetModuleHandleA(NULL)) return NULL;
    return (IDirect3DDevice9 *)dev;
}

/* --- resource creation (once, on the render thread inside Present) --- */
static void FillCube(float *v /*8*3*/, unsigned short *idx /*36*/) {
    static const float c[8][3] = {
        {-1,-1,-1},{1,-1,-1},{1,1,-1},{-1,1,-1},{-1,-1,1},{1,-1,1},{1,1,1},{-1,1,1} };
    static const unsigned short id[36] = {
        0,1,2, 0,2,3,  4,6,5, 4,7,6,  0,4,5, 0,5,1,
        3,2,6, 3,6,7,  1,5,6, 1,6,2,  0,3,7, 0,7,4 };
    int i;
    for (i=0;i<24;i++) v[i]=c[i/3][i%3];
    for (i=0;i<36;i++) idx[i]=id[i];
}
/* per-instance = 4 float4 rows of a clip-space scale+translate matrix (row-major; dp4(pos,row)=clip) */
static void FillInstances(float *m /*NUM_INST*16*/) {
    int i, gx, gy; float s = 0.15f;
    for (i=0;i<NUM_INST;i++) {
        gx = i % GRID; gy = i / GRID;
        float tx = -0.75f + gx*0.5f, ty = -0.75f + gy*0.5f, tz = 0.5f;
        float *r = m + i*16;
        r[0]=s; r[1]=0; r[2]=0; r[3]=tx;   /* row0 */
        r[4]=0; r[5]=s; r[6]=0; r[7]=ty;   /* row1 */
        r[8]=0; r[9]=0; r[10]=s; r[11]=tz; /* row2 */
        r[12]=0;r[13]=0;r[14]=0; r[15]=1;  /* row3 */
    }
}
static int CreateResources(IDirect3DDevice9 *dev) {
    static const D3DVERTEXELEMENT9 decl[] = {
        {0, 0,  D3DDECLTYPE_FLOAT3, D3DDECLMETHOD_DEFAULT, D3DDECLUSAGE_POSITION, 0},
        {1, 0,  D3DDECLTYPE_FLOAT4, D3DDECLMETHOD_DEFAULT, D3DDECLUSAGE_TEXCOORD, 0},
        {1, 16, D3DDECLTYPE_FLOAT4, D3DDECLMETHOD_DEFAULT, D3DDECLUSAGE_TEXCOORD, 1},
        {1, 32, D3DDECLTYPE_FLOAT4, D3DDECLMETHOD_DEFAULT, D3DDECLUSAGE_TEXCOORD, 2},
        {1, 48, D3DDECLTYPE_FLOAT4, D3DDECLMETHOD_DEFAULT, D3DDECLUSAGE_TEXCOORD, 3},
        D3DDECL_END()
    };
    void *ptr; HRESULT hr;
    hr = IDirect3DDevice9_CreateVertexShader(dev, (const DWORD*)g_splicedVS, &g_vs);
    if (FAILED(hr)) { Log("CreateVertexShader(spliced) FAILED 0x%08lX", hr); return 0; }
    hr = IDirect3DDevice9_CreatePixelShader(dev, g_ps, &g_ps_obj);
    if (FAILED(hr)) { Log("CreatePixelShader FAILED 0x%08lX", hr); return 0; }
    hr = IDirect3DDevice9_CreateVertexDeclaration(dev, decl, &g_decl);
    if (FAILED(hr)) { Log("CreateVertexDeclaration FAILED 0x%08lX", hr); return 0; }
    hr = IDirect3DDevice9_CreateVertexBuffer(dev, 8*3*4, 0, 0, D3DPOOL_MANAGED, &g_cubeVB, NULL);
    if (FAILED(hr)) { Log("cubeVB FAILED 0x%08lX", hr); return 0; }
    hr = IDirect3DDevice9_CreateIndexBuffer(dev, 36*2, 0, D3DFMT_INDEX16, D3DPOOL_MANAGED, &g_cubeIB, NULL);
    if (FAILED(hr)) { Log("cubeIB FAILED 0x%08lX", hr); return 0; }
    hr = IDirect3DDevice9_CreateVertexBuffer(dev, NUM_INST*16*4, 0, 0, D3DPOOL_MANAGED, &g_instVB, NULL);
    if (FAILED(hr)) { Log("instVB FAILED 0x%08lX", hr); return 0; }
    /* fill cube VB */
    if (SUCCEEDED(IDirect3DVertexBuffer9_Lock(g_cubeVB, 0, 0, &ptr, 0))) {
        unsigned short tmp[36]; FillCube((float*)ptr, tmp); IDirect3DVertexBuffer9_Unlock(g_cubeVB); }
    if (SUCCEEDED(IDirect3DIndexBuffer9_Lock(g_cubeIB, 0, 0, &ptr, 0))) {
        float dummy[24]; FillCube(dummy, (unsigned short*)ptr); IDirect3DIndexBuffer9_Unlock(g_cubeIB); }
    if (SUCCEEDED(IDirect3DVertexBuffer9_Lock(g_instVB, 0, 0, &ptr, 0))) {
        FillInstances((float*)ptr); IDirect3DVertexBuffer9_Unlock(g_instVB); }
    Log("resources created (spliced VS accepted; %d instances)", NUM_INST);
    return 1;
}

static void DrawInstanced(IDirect3DDevice9 *dev) {
    static const float I[16] = {1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1};
    IDirect3DStateBlock9 *sb = NULL;
    if (FAILED(IDirect3DDevice9_CreateStateBlock(dev, D3DSBT_ALL, &sb))) return;  /* save */

    IDirect3DDevice9_SetRenderState(dev, D3DRS_ZENABLE, FALSE);
    IDirect3DDevice9_SetRenderState(dev, D3DRS_ZWRITEENABLE, FALSE);
    IDirect3DDevice9_SetRenderState(dev, D3DRS_CULLMODE, D3DCULL_NONE);
    IDirect3DDevice9_SetRenderState(dev, D3DRS_ALPHABLENDENABLE, FALSE);
    IDirect3DDevice9_SetRenderState(dev, D3DRS_ALPHATESTENABLE, FALSE);
    IDirect3DDevice9_SetRenderState(dev, D3DRS_FILLMODE, D3DFILL_SOLID);
    IDirect3DDevice9_SetRenderState(dev, D3DRS_STENCILENABLE, FALSE);
    IDirect3DDevice9_SetRenderState(dev, D3DRS_SCISSORTESTENABLE, FALSE);
    IDirect3DDevice9_SetRenderState(dev, D3DRS_COLORWRITEENABLE, 0x0F);

    IDirect3DDevice9_SetVertexShader(dev, g_vs);
    IDirect3DDevice9_SetPixelShader(dev, g_ps_obj);
    IDirect3DDevice9_SetVertexShaderConstantF(dev, 0, I, 4);   /* viewContextData c0..c3 = identity */
    IDirect3DDevice9_SetVertexDeclaration(dev, g_decl);

    /* geometry stream (0) replayed once per instance; instance stream (1) advances per instance */
    IDirect3DDevice9_SetStreamSource(dev, 0, g_cubeVB, 0, 3*4);
    IDirect3DDevice9_SetStreamSourceFreq(dev, 0, D3DSTREAMSOURCE_INDEXEDDATA | NUM_INST);
    IDirect3DDevice9_SetStreamSource(dev, 1, g_instVB, 0, 16*4);
    IDirect3DDevice9_SetStreamSourceFreq(dev, 1, D3DSTREAMSOURCE_INSTANCEDATA | 1);
    IDirect3DDevice9_SetIndices(dev, g_cubeIB);

    HRESULT hr = IDirect3DDevice9_DrawIndexedPrimitive(dev, D3DPT_TRIANGLELIST, 0, 0, 8, 0, 12);

    IDirect3DDevice9_SetStreamSourceFreq(dev, 0, 1);
    IDirect3DDevice9_SetStreamSourceFreq(dev, 1, 1);
    IDirect3DStateBlock9_Apply(sb);      /* restore */
    IDirect3DStateBlock9_Release(sb);

    if (!g_logged_draw) {
        g_logged_draw = 1;
        Log("==== INSTANCED DIP issued: 1 DrawIndexedPrimitive, %d instances (hr=0x%08lX) ====",
            NUM_INST, hr);
        Log("     SetStreamSourceFreq(0, INDEXEDDATA|%d) + (1, INSTANCEDATA|1); spliced PgMesh VS bound.",
            NUM_INST);
        if (SUCCEEDED(hr)) Log("     If a 4x4 magenta cube grid is on screen, R1 is PROVEN. Snip it.");
    }
}

static HRESULT WINAPI MyPresent(IDirect3DDevice9 *dev, const RECT *a, const RECT *b, HWND c, const RGNDATA *d) {
    if (!g_disabled && dev) {
        if (!g_res_tried) { g_res_tried = 1; g_res_ok = CreateResources(dev); }
        if (g_res_ok) DrawInstanced(dev);
    }
    return g_origPresent(dev, a, b, c, d);
}

static void HookPresent(IDirect3DDevice9 *dev) {
    IDirect3DDevice9Vtbl *vt = (IDirect3DDevice9Vtbl *)dev->lpVtbl;
    DWORD old;
    g_origPresent = vt->Present;
    if (VirtualProtect(&vt->Present, sizeof(void *), PAGE_EXECUTE_READWRITE, &old)) {
        vt->Present = MyPresent;
        VirtualProtect(&vt->Present, sizeof(void *), old, &old);
        Log("Present hooked (vtbl+0x44); instanced draw armed. orig=%p", (void*)g_origPresent);
    } else {
        Log("VirtualProtect on Present FAILED — not armed");
    }
}

static DWORD WINAPI Worker(LPVOID arg) {
    int waited = 0; (void)arg;
    char *env = NULL; static char buf[8];
    if (GetEnvironmentVariableA("DENSITY_INSTANCE_PROBE", buf, sizeof(buf)) && buf[0]=='0') {
        g_disabled = 1; Log("disabled via DENSITY_INSTANCE_PROBE=0"); }
    (void)env;
    while (waited < 400) {                 /* up to ~100s for the device */
        g_dev = ResolveDevice();
        if (g_dev) break;
        Sleep(250); waited++;
    }
    if (!g_dev) { Log("device never resolved — not armed"); return 0; }
    Log("device resolved: %p", (void*)g_dev);
    HookPresent(g_dev);
    return 0;
}

static void LogInit(void) {
    char path[MAX_PATH], *slash;
    GetModuleFileNameA(NULL, path, MAX_PATH);
    slash = strrchr(path, '\\');
    if (slash) lstrcpyA(slash + 1, "density_instance_probe.log"); else lstrcpyA(path, "density_instance_probe.log");
    g_log = CreateFileA(path, GENERIC_WRITE, FILE_SHARE_READ, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
}

BOOL WINAPI DllMain(HINSTANCE h, DWORD reason, LPVOID r) {
    (void)r;
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(h);
        LogInit();
        Log("============================================");
        Log("density_instance_probe.asi loaded (PID %lu) — R1 instanced-draw proof",
            (unsigned long)GetCurrentProcessId());
        CreateThread(NULL, 0, Worker, NULL, 0, NULL);
    } else if (reason == DLL_PROCESS_DETACH) {
        if (g_log != INVALID_HANDLE_VALUE) CloseHandle(g_log);
    }
    return TRUE;
}
