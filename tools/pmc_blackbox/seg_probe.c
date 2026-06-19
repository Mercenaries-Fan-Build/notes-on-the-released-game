/**
 * seg_probe.c — terrainmesh segment-pointer off-by-4 compensation.
 *
 * World-load CTD at 0x4AB26B (only with the DLC WAD present): the model render
 * walk follows a per-segment pointer [rec+4] and reads its sub-array base from
 * [seg+0x2c]. RCA (decompile + live crash capture + builder hooks) showed these
 * segment structs are allocated [count][struct] (a 4-byte count prefix; the
 * usable struct begins at alloc+4), and the builder FUN_004a9da0 correctly fills
 * the struct at alloc+4 — but the pointer stored in the model record (rec+4)
 * points at the PREFIX (alloc) instead of the struct (alloc+4). So the render
 * reads every field 4 bytes early: [seg+0x2c] hits countB (a small int, e.g. 3)
 * where it expects ptrB → AV. This happens only with the DLC overlay loaded
 * (base + pmc_bb alone loads the world fully).
 *
 * The malformed (off-by-4) segment has a unique, safe signature:
 *     [seg+0x28] is a heap pointer (ptrA)  AND  [seg+0x2c] is a small int (countB)
 * a CORRECT segment is the mirror image: [seg+0x28] small, [seg+0x2c] a pointer.
 *
 * FIX: patch the render walk where it loads the segment pointer
 *     0x4AB240  mov ebp,[ecx+4]          (8B 69 04)
 *     0x4AB243  add ebp,[esp+0x10]       (03 6C 24 10)
 * to detour through a cave that, when it detects the off-by-4 signature, advances
 * ebp by 4 to the real struct — so the existing read at 0x4AB266 lands on ptrB.
 * Self-correcting: correct segments (and empty ones) are left untouched, so the
 * one render path that serves every model stays valid. Reversible byte patch.
 */
/*
 * TWO render paths read the terrain segment off-by-4, in two different functions:
 *   SITE A  0x4AB240  mov ebp,[ecx+4]; add ebp,[esp+0x10]   -> crashed at 0x4AB266
 *   SITE B  0x4AAFD0  mov edi,[eax+4]; add edi,[esp+0x10]   -> crashed at 0x4AB051
 * Both load a segment pointer that aims at the [count] prefix (alloc) instead of
 * the struct (alloc+4), then read [seg+0x2c] expecting ptrB but getting countB (a
 * small int) -> AV. SITE A was found first; SITE B surfaced only once SITE A + the
 * PRMG guard let the load reach it. Same fix, different register, so a generic
 * installer arms both: detour the 7-byte load through a cave that advances the
 * segment pointer by 4 when it carries the off-by-4 signature
 *     [seg+0x28] is a heap pointer  AND  [seg+0x2c] is a small int
 * and leaves correct/empty segments untouched (the render path serves every model).
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

extern void pmc_log(const char *source, const char *fmt, ...);
extern void pmc_log_flush(void);

#define PATCH_LEN    7u
#define PTR_MIN      0x00010000u   /* below this = not a heap pointer (a count) */

/* Install one off-by-4 corrector. cmp_modrm/add_modrm select the segment register:
 *   ebp -> cmp [ebp+d8] = 81 7D, add ebp,4 = 83 C5 04
 *   edi -> cmp [edi+d8] = 81 7F, add edi,4 = 83 C7 04
 * orig7 is the exact 7-byte load (mov reg,[base+4]; add reg,[esp+0x10]) we replace. */
static int install_offby4(const char *tag, DWORD patch_va, DWORD resume_va,
                          const unsigned char orig7[PATCH_LEN],
                          unsigned char cmp_modrm, unsigned char add_modrm)
{
    DWORD oldp;
    unsigned char *p, *cave;
    unsigned char *q = (unsigned char *)patch_va;
    int i;

    /* Verify the bytes we're about to replace (guard against a different exe). */
    for (i = 0; i < (int)PATCH_LEN; i++) {
        if (q[i] != orig7[i]) {
            pmc_log("seg", "off-by-4 fix %s NOT applied: bytes @0x%08X mismatch "
                    "(found %02X at +%d, expected %02X). Source [seg].",
                    tag, patch_va, q[i], i, orig7[i]);
            return 0;
        }
    }

    cave = (unsigned char *)VirtualAlloc(NULL, 64, MEM_COMMIT | MEM_RESERVE,
                                         PAGE_EXECUTE_READWRITE);
    if (!cave) {
        pmc_log("seg", "off-by-4 fix %s: VirtualAlloc(cave) failed.", tag);
        return 0;
    }

    /* Build the cave (reg = ebp or edi per modrm args):
     *   <orig 7 bytes>                  ; mov reg,[base+4]; add reg,[esp+0x10]
     *   cmp dword [reg+0x28], 0x10000   81 <modrm> 28 00 00 01 00 ; ptrA present?
     *   jb  skip                        72 0C                      ; +0x28 not ptr -> leave
     *   cmp dword [reg+0x2c], 0x10000   81 <modrm> 2C 00 00 01 00 ; countB small?
     *   jae skip                        73 03                      ; +0x2c is ptr -> correct
     *   add reg, 4                      83 <modrm> 04              ; off-by-4 -> advance
     * skip:
     *   jmp resume_va                   E9 <rel32>
     */
    p = cave;
    for (i = 0; i < (int)PATCH_LEN; i++) *p++ = orig7[i];        /* original load        */
    *p++=0x81; *p++=cmp_modrm; *p++=0x28; *p++=0x00; *p++=0x00; *p++=0x01; *p++=0x00; /* cmp [reg+28],10000h */
    *p++=0x72; *p++=0x0C;                                        /* jb skip              */
    *p++=0x81; *p++=cmp_modrm; *p++=0x2C; *p++=0x00; *p++=0x00; *p++=0x01; *p++=0x00; /* cmp [reg+2c],10000h */
    *p++=0x73; *p++=0x03;                                        /* jae skip             */
    *p++=0x83; *p++=add_modrm; *p++=0x04;                        /* add reg,4            */
    /* skip: jmp resume_va */
    *p++=0xE9;
    {
        DWORD rel = resume_va - ((DWORD)(ULONG_PTR)p + 4);
        *p++ = (unsigned char)(rel & 0xFF);
        *p++ = (unsigned char)((rel >> 8) & 0xFF);
        *p++ = (unsigned char)((rel >> 16) & 0xFF);
        *p++ = (unsigned char)((rel >> 24) & 0xFF);
    }

    /* Patch patch_va: jmp cave (E9 rel32) + 2x NOP padding (overwrites 7 bytes). */
    if (!VirtualProtect((LPVOID)patch_va, PATCH_LEN, PAGE_EXECUTE_READWRITE, &oldp)) {
        pmc_log("seg", "off-by-4 fix %s: VirtualProtect failed.", tag);
        return 0;
    }
    {
        DWORD rel = (DWORD)(ULONG_PTR)cave - (patch_va + 5);
        q[0] = 0xE9;
        q[1] = (unsigned char)(rel & 0xFF);
        q[2] = (unsigned char)((rel >> 8) & 0xFF);
        q[3] = (unsigned char)((rel >> 16) & 0xFF);
        q[4] = (unsigned char)((rel >> 24) & 0xFF);
        q[5] = 0x90;
        q[6] = 0x90;
    }
    VirtualProtect((LPVOID)patch_va, PATCH_LEN, oldp, &oldp);
    FlushInstructionCache(GetCurrentProcess(), (LPVOID)patch_va, PATCH_LEN);

    pmc_log("seg", "segment off-by-4 fix %s ARMED @0x%08X -> cave %p: advances the "
            "segment ptr by 4 when [+0x28]=ptr & [+0x2c]=count. Source [seg].",
            tag, patch_va, (void *)cave);
    return 1;
}

int InstallSegProbe(void)   /* name kept; called from pmc_blackbox.c */
{
    int n = 0;
    /* All four terrain segment-pointer loads (mov reg,[base+4]; add reg,[esp+d8])
     * found by scanning 0x4A9000-0x4AB400. Correcting the pointer at the LOAD fixes
     * every off-by-4 read downstream in that loop (the reads use varied forms:
     * [reg+0x24], [reg+0x2c], [eax+reg+...]), so per-read patches are unneeded.
     * cmp_modrm/add_modrm: edi -> 7F/C7, ebp -> 7D/C5. */
    /* SITE A — FUN_004ab0d0-region, crashed at 0x4AB266 (ebp). */
    static const unsigned char origA[PATCH_LEN] = {0x8B,0x69,0x04, 0x03,0x6C,0x24,0x10};
    n += install_offby4("A@0x4AB240", 0x004AB240u, 0x004AB247u, origA, 0x7D, 0xC5);
    /* SITE B — terrain function below 0x4ab0d0, crashed at 0x4AB051 (edi, [esp+0x10]). */
    static const unsigned char origB[PATCH_LEN] = {0x8B,0x78,0x04, 0x03,0x7C,0x24,0x10};
    n += install_offby4("B@0x4AAFD0", 0x004AAFD0u, 0x004AAFD7u, origB, 0x7F, 0xC7);
    /* SITE C — same terrain function, another inner loop (edi from esi, [esp+0x10]). */
    static const unsigned char origC[PATCH_LEN] = {0x8B,0x7E,0x04, 0x03,0x7C,0x24,0x10};
    n += install_offby4("C@0x4A9CDC", 0x004A9CDCu, 0x004A9CE3u, origC, 0x7F, 0xC7);
    /* SITE D — same terrain function, the loop that crashed at 0x4AAD87 (edi, [esp+0x1c]). */
    static const unsigned char origD[PATCH_LEN] = {0x8B,0x79,0x04, 0x03,0x7C,0x24,0x1C};
    n += install_offby4("D@0x4AAC64", 0x004AAC64u, 0x004AAC6Bu, origD, 0x7F, 0xC7);
    pmc_log_flush();
    return n;
}
