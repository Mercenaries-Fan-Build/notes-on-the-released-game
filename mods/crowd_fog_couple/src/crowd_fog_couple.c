/**
 * crowd_fog_couple.asi — make the ambient crowd (count + reach) fill the world out to the fog, so
 * crowds dissolve INTO the fog instead of popping out of clear air. Runtime-only, no exe/WAD edit.
 *
 * FOUR coupled patches (all verified against output/_ghidra/securom_dump/image.bin, ImageBase
 * 0x400000; see docs/reverse_engineer/render_distance_and_density_levers.md):
 *
 *   1. FOG -> D. Force DAT_00dfc348 (INI ViewDistance) so fog far = VD*20+400 = D. Enforced every
 *      tick (the video-options menu can't reset it). Only the INI global reaches fog; the in-game
 *      slider is inert.
 *
 *   2. DESPAWN CULL -> D. FUN_00501f20 (ambient cache-out gate) culls entities past a squared
 *      distance picked from a per-mode set. Redirect its 9 threshold `movss xmm,[disp32]` loads to a
 *      private D^2 float. Operand rewrite, NOT the shared constants (they serve 9-13 other systems).
 *
 *   3. SPAWN REACH -> R. FUN_005049b0 places the per-player ambient activation ring at
 *      player + unitcircle*DAT_00b984ac (50 m). That constant is shared by 59 functions, so we
 *      redirect ONLY its placement-load operand (MOVSS xmm2,[0x00b984ac] @0x00504b2d, disp32
 *      @0x00504b31) to a private R float; the in-function fade load (FLD @0x00504bd1) is untouched.
 *
 *   4. DENSITY CEILING xN. The crowd count ceiling is the desired ped/veh counts FUN_004d60e0 writes
 *      into DAT_00ed55c8[]/DAT_00ed55b0[] from the region's PopulationDensity data (DensityUpdate
 *      FUN_005051a0 then spawns toward them; the batch is fill-RATE only, and the engine already
 *      x2's peds in free-roam). MinHook FUN_004d60e0: after the original fills the arrays, multiply
 *      each by CROWD_DENSITY_MULT, clamped to CROWD_PED_CAP / CROWD_VEH_CAP so we stay inside the
 *      STOCK pools (Ai 1024 shared with enemies/mission NPCs; ControllerCar 64 AI-car hard cap).
 *      Going past the caps needs a cdbsizes.ini pool bump -- deliberately NOT done here.
 *
 * Tunables (env): CROWD_FOG_DIST (metres, >=400, default 400 -> drives fog+cull+reach together),
 *   CROWD_PLACE_RADIUS (override reach only; default = CROWD_FOG_DIST), CROWD_DENSITY_MULT (default
 *   3.0), CROWD_PED_CAP (default 200), CROWD_VEH_CAP (default 15).
 *
 * 32-bit DLL, loaded by the ASI loader from <game>/scripts/. Byte-signature guards abort any patch
 * that doesn't match (wrong build -> nothing changed). Writes crowd_fog_couple.log next to the exe.
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "MinHook.h"

/* ---- image VAs (ImageBase 0x400000) ---- */
#define VA_IMAGEBASE   0x00400000u
#define VA_FUN_CULL    0x00501f20u   /* ambient cache-out distance gate */
#define FN_CULL_SIZE   0x1b5u
#define VA_VIEWDIST    0x00dfc348u   /* INI ViewDistance (int) -> fog */
#define VA_PLACE_OP    0x00504b31u   /* disp32 of MOVSS xmm2,[b984ac] in FUN_005049b0 (reach) */
#define VA_B984AC      0x00b984acu   /* the 50.0 the reach operand currently points at */
#define VA_FUN_REGION  0x004d60e0u   /* FUN_004d60e0 = region-select desired-count writer */
#define VA_ED55C8      0x00ed55c8u   /* per-player desired PED count array */
#define VA_ED55B0      0x00ed55b0u   /* per-player desired VEHICLE count array */
#define VA_PLAYERCNT   0x01175d80u   /* DAT_01175d80 = active player/viewport count */
#define VA_FUN_LOD     0x00490220u   /* FUN_00490220 = RtGenericLOD per-frame band consumer */

/* the 9 squared-distance threshold constants FUN_00501f20 loads (each via `F3 0F 10 xx <disp32>`) */
static const DWORD g_threshVA[] = {
    0x00d1e408u,0x00d1e40cu,0x00d1e410u,0x00d1e414u,
    0x00bea9b0u,0x00beab3cu,0x00beaeb0u,0x00beaeb4u,0x00beaaa8u
};
#define N_THRESH (sizeof(g_threshVA)/sizeof(g_threshVA[0]))

/* private floats the redirected loads point at (must outlive the process) */
static volatile float g_cullSq  = 160000.0f;   /* D^2  (default 400^2) */
static volatile float g_reach   = 400.0f;      /* R    (default 400 m ambient ring radius) */

static int    g_viewDist = 0;
static float  g_dist     = 400.0f;
static float  g_densMul  = 3.0f;
static int    g_pedCap   = 200;
static int    g_vehCap   = 15;
static float  g_lodCoarseSq = 1000000.0f;   /* geometry: coarse/base band far² (1000²) */
static float  g_lodDetailSq =  640000.0f;   /* geometry: higher-detail band far² (800²) */
static DWORD  g_delta    = 0;

static char g_logPath[MAX_PATH];
static void Log(const char *fmt, ...) {
    FILE *f = fopen(g_logPath, "a"); if (!f) return;
    va_list ap; va_start(ap, fmt); vfprintf(f, fmt, ap); va_end(ap);
    fputc('\n', f); fclose(f);
}

static int PatchMem(void *addr, const void *src, SIZE_T n) {
    DWORD old;
    if (!VirtualProtect(addr, n, PAGE_EXECUTE_READWRITE, &old)) return 0;
    memcpy(addr, src, n);
    VirtualProtect(addr, n, old, &old);
    FlushInstructionCache(GetCurrentProcess(), addr, n);
    return 1;
}

/* ---- patch 2: redirect the 9 cull thresholds in FUN_00501f20 -> &g_cullSq ---- */
static int RedirectCull(DWORD delta) {
    BYTE *fn = (BYTE *)(VA_FUN_CULL + delta);
    DWORD tgt = (DWORD)(DWORD_PTR)&g_cullSq;
    DWORD off[N_THRESH]; int found = 0;
    for (DWORD k = 0; k < N_THRESH; k++) {
        DWORD want = g_threshVA[k] + delta; int got = 0;
        for (DWORD i = 4; i + 4 <= FN_CULL_SIZE; i++)
            if (*(DWORD *)(fn + i) == want && fn[i-4]==0xF3 && fn[i-3]==0x0F && fn[i-2]==0x10) {
                off[found++] = i; got = 1; break;
            }
        if (!got) Log("  [cull] operand %u (VA 0x%08x) not found", k, g_threshVA[k]);
    }
    if (found != (int)N_THRESH) { Log("  [cull] ABORT %d/%u -- no bytes changed", found, (unsigned)N_THRESH); return -1; }
    for (int s = 0; s < found; s++) PatchMem(fn + off[s], &tgt, 4);
    Log("  [cull] redirected %d/%u loads -> %.0f m", found, (unsigned)N_THRESH, g_cullSq > 0.0f ? (float)sqrt((double)g_cullSq) : 0.0f);
    return found;
}

/* ---- patch 3: redirect the ambient-ring reach operand in FUN_005049b0 -> &g_reach ---- */
static int RedirectReach(DWORD delta) {
    BYTE *op = (BYTE *)(VA_PLACE_OP + delta);          /* the disp32 itself */
    /* verify the MOVSS xmm2 opcode + expected current target sit exactly where documented */
    if (op[-4]!=0xF3 || op[-3]!=0x0F || op[-2]!=0x10 || op[-1]!=0x15 ||
        *(DWORD *)op != (VA_B984AC + delta)) {
        Log("  [reach] ABORT: signature @0x%08x = %02x %02x %02x %02x disp=0x%08x -- not patched",
            VA_PLACE_OP, op[-4],op[-3],op[-2],op[-1], *(DWORD*)op);
        return -1;
    }
    DWORD tgt = (DWORD)(DWORD_PTR)&g_reach;
    PatchMem(op, &tgt, 4);
    Log("  [reach] ambient ring radius -> %.0f m", g_reach);
    return 1;
}

/* ---- patch 4: density hook on FUN_004d60e0 ---- */
typedef void (*regionfn_t)(void);
static regionfn_t o_region = NULL;
static void hk_region(void) {
    o_region();                                        /* original fills the desired-count arrays */
    int n = *(volatile int *)(VA_PLAYERCNT + g_delta);
    if (n < 0 || n > 8) return;
    int *ped = (int *)(VA_ED55C8 + g_delta);
    int *veh = (int *)(VA_ED55B0 + g_delta);
    for (int i = 0; i < n; i++) {
        long p = (long)((float)ped[i] * g_densMul + 0.5f);
        long v = (long)((float)veh[i] * g_densMul + 0.5f);
        if (p > g_pedCap) p = g_pedCap;
        if (v > g_vehCap) v = g_vehCap;
        if (p > ped[i]) ped[i] = (int)p;               /* only ever raise, never lower */
        if (v > veh[i]) veh[i] = (int)v;
    }
}

/* ---- patch 5: geometry render distance via the RtGenericLOD band consumer FUN_00490220 ----
 * Each LOD object carries up to 4 bands {near²@+0, far²@+4, ?, handle} at [obj+0], count @[obj+0x40];
 * a band's mesh is resident iff near² <= camDist² < far². We rewrite the far² each frame so the
 * COARSEST band (largest far²) stays visible to `coarse` m and every finer band to `detail` m. We
 * touch only far² (never near²), so this can extend visibility but never HIDE geometry. Covers the
 * RtGenericLOD/proxy set (vegetation/trees + authored-LOD objects); mass HibernationControl-only props
 * are a separate gate. */
typedef void (*lodfn_t)(int, unsigned);
static lodfn_t o_lod = NULL;
static void hk_lod(int obj, unsigned p2) {
    if (obj) {
        int n = *(volatile int *)(obj + 0x40);
        if (n > 0 && n <= 4) {
            int   maxi = 0;
            float maxf = *(float *)(obj + 4);
            for (int i = 1; i < n; i++) {
                float f = *(float *)(obj + i * 0x10 + 4);
                if (f > maxf) { maxf = f; maxi = i; }
            }
            for (int i = 0; i < n; i++)
                *(float *)(obj + i * 0x10 + 4) = (i == maxi) ? g_lodCoarseSq : g_lodDetailSq;
        }
    }
    o_lod(obj, p2);
}

static void EnforceFog(DWORD delta) {
    volatile int *vd = (volatile int *)(VA_VIEWDIST + delta);
    if (*vd >= 0 && *vd <= 100000 && *vd != g_viewDist) *vd = g_viewDist;
}

static float EnvF(const char *k, float def, float lo, float hi) {
    const char *e = getenv(k); if (!e || !*e) return def;
    float v = (float)atof(e); return (v < lo) ? lo : (v > hi) ? hi : v;
}

static DWORD WINAPI Worker(LPVOID u) {
    (void)u;
    DWORD modBase = (DWORD)(DWORD_PTR)GetModuleHandleA(NULL);
    g_delta = modBase - VA_IMAGEBASE;

    g_dist    = EnvF("CROWD_FOG_DIST",    800.0f, 400.0f, 4000.0f);          /* fog distance */
    g_reach   = EnvF("CROWD_PLACE_RADIUS", 1000.0f, 20.0f, 4000.0f);         /* crowd spawn reach */
    g_densMul = EnvF("CROWD_DENSITY_MULT",  3.0f,   1.0f,   20.0f);
    g_pedCap  = (int)EnvF("CROWD_PED_CAP", 200.0f,  1.0f, 4000.0f);
    g_vehCap  = (int)EnvF("CROWD_VEH_CAP",  15.0f,  1.0f,   60.0f);
    { float c = EnvF("RENDER_COARSE_DIST", 1000.0f, 50.0f, 4000.0f);   /* base geometry visible to */
      float d = EnvF("RENDER_DETAIL_DIST",  800.0f, 50.0f, 4000.0f);   /* higher-detail LOD within */
      g_lodCoarseSq = c * c; g_lodDetailSq = d * d; }
    /* the despawn cull must outlast the spawn reach, or peds spawned past the fog are culled before
     * they can persist inward -- so cull = max(fog, reach). */
    { float cull = (g_reach > g_dist) ? g_reach : g_dist; g_cullSq = cull * cull; }
    g_viewDist = (int)((g_dist - 400.0f) / 20.0f + 0.5f);

    Log("crowd_fog_couple.asi loaded (PID %lu) modBase 0x%08x delta 0x%08x -- fog %.0f m, cull %.0f m, "
        "reach %.0f m, density x%.1f (ped<=%d veh<=%d)", GetCurrentProcessId(), modBase, g_delta,
        g_dist, (g_reach > g_dist ? g_reach : g_dist), g_reach, g_densMul, g_pedCap, g_vehCap);

    /* one-shot .text redirects (retry until .text is settled) */
    int cull = 0, reach = 0;
    for (int a = 0; a < 20 && !(cull && reach); a++) {
        if (!cull  && RedirectCull(g_delta)  == (int)N_THRESH) cull  = 1;
        if (!reach && RedirectReach(g_delta) == 1)             reach = 1;
        if (!(cull && reach)) Sleep(250);
    }
    if (!cull)  Log("  [cull] gave up -- crowd cull left at stock");
    if (!reach) Log("  [reach] gave up -- ambient ring left at 50 m");

    /* density + geometry-LOD hooks (MinHook) */
    if (MH_Initialize() == MH_OK) {
        void *dtgt = (void *)(VA_FUN_REGION + g_delta);
        if (MH_CreateHook(dtgt, (void *)&hk_region, (void **)&o_region) == MH_OK &&
            MH_EnableHook(dtgt) == MH_OK)
            Log("  [density] hooked FUN_004d60e0 -> x%.1f (ped<=%d veh<=%d)", g_densMul, g_pedCap, g_vehCap);
        else
            Log("  [density] MinHook create/enable FAILED -- density left at stock");

        void *ltgt = (void *)(VA_FUN_LOD + g_delta);
        if (MH_CreateHook(ltgt, (void *)&hk_lod, (void **)&o_lod) == MH_OK &&
            MH_EnableHook(ltgt) == MH_OK)
            Log("  [geometry] hooked FUN_00490220 -> coarse %.0f m / detail %.0f m",
                (float)sqrt((double)g_lodCoarseSq), (float)sqrt((double)g_lodDetailSq));
        else
            Log("  [geometry] MinHook create/enable FAILED -- LOD render distance left at stock");
    } else {
        Log("  [density] MH_Initialize FAILED -- density + geometry left at stock");
    }

    for (;;) { EnforceFog(g_delta); Sleep(1000); }
}

BOOL WINAPI DllMain(HINSTANCE h, DWORD reason, LPVOID r) {
    (void)r;
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(h);
        GetModuleFileNameA(GetModuleHandleA(NULL), g_logPath, MAX_PATH);
        char *slash = strrchr(g_logPath, '\\');
        if (slash) strcpy(slash + 1, "crowd_fog_couple.log"); else strcpy(g_logPath, "crowd_fog_couple.log");
        CreateThread(NULL, 0, Worker, NULL, 0, NULL);
    }
    return TRUE;
}
