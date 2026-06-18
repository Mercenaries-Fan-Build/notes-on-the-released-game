/**
 * prmg_guard.c — skip terrain/mesh primitive-group elements whose render
 * resource handle failed to resolve (the 0x47AA5C world-load crash).
 *
 * After the 0x4AB240 segment off-by-4 fix [seg] held, the load reaches mission
 * flow / faction setup / "Loading Mission State" and then CTDs (VEH-caught, but
 * per-frame) at:
 *     0x0047AA5C  cmp dword [ebx+0xfc], 0     ; AV READ, ebx == 0
 *
 * RCA (decompile FUN_0047aa20 render + FUN_00478270 PRMG/INFO parse):
 *   The renderable (this) holds a count (this+4) array of 0x1C4-byte primitive-
 *   group records at this+8. Each record's +0 and +4 are RENDER-RESOURCE HANDLES
 *   filled at INFO-parse time from a 256-entry hash registry:
 *       slot = FUN_008242b0(key, 0x100)  over key table 0x197de48
 *       handle = (slot<0) ? *0x197da44(=NULL sentinel) : *(0x197da48 + slot*4)
 *   The two keys are ADJACENT INFO dwords (record+0 key = INFO+0x24, record+4 key
 *   = INFO+0x20). For the crashing terrain record, record+0 resolved (handle
 *   0x08270420) but record+4's key MISSED the registry -> record+4 = NULL. The
 *   render path then derefs record+4 unconditionally (cmp [ebx+0xfc] at 0x47AA5C;
 *   then mov cx,[esi+8] at 0x47AAC6, push esi vcall, mov eax,[esi+0x110]) so the
 *   whole element is unusable, not just the first field.
 *
 * Whether the miss is a converter-mangled INFO key (most likely — adjacent-field
 * partial swap, same class as the MTRL flags/count transposition) or a missing
 * DLC resource registration is still TBD; this guard does not fix that, it lets
 * the load proceed so the rest of the world renders while the real key fix lands.
 *
 * FIX: detour the loop-top resource-load
 *     0x47AA47  mov eax,[edi+0x14]   (8B 47 14)   iVar3 = this+0x14
 *     0x47AA4A  test eax,eax         (85 C0)
 * through a cave that peeks record+4 ([ebp+4]); if it is NULL, jump to the
 * per-element increment block at 0x47ABA0 (skip this primitive group); otherwise
 * re-establish the original eax/ZF and resume at 0x47AA4C. NULL record+4 only
 * occurs on a registry miss (a valid handle is always a heap pointer), so the
 * test is exact and touches nothing else. Reversible byte patch.
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

extern void pmc_log(const char *source, const char *fmt, ...);
extern void pmc_log_flush(void);

#define PATCH_VA   0x0047AA47u   /* mov eax,[edi+0x14]; test eax,eax (5 bytes) */
#define RESUME_VA  0x0047AA4Cu   /* next instruction (mov ebx,[ebp+4]) */
#define SKIP_VA    0x0047ABA0u   /* per-element increment block (skip this element) */
#define PATCH_LEN  5u

/* original 5 bytes we expect at PATCH_VA (verify before patching). */
static const unsigned char g_orig[PATCH_LEN] = {0x8B,0x47,0x14, 0x85,0xC0};

static unsigned char *g_cave = NULL;

/* Returns 1 if the PRMG record+4 render-resource handle is unusable (NULL, or not
 * readable through [handle+0x110]), so the element must be skipped. __cdecl, and
 * leaves ebx/esi/edi/ebp intact (callee-saved) for the cave that calls it.
 * VirtualQuery never faults, so this is safe to call on a wild pointer. */
int __cdecl prmg_bad_handle(void *h)
{
    MEMORY_BASIC_INFORMATION mbi;
    ULONG_PTR base = (ULONG_PTR)h;
    ULONG_PTR need = base + 0x114u;          /* must read up to [h+0x110] (4 bytes) */
    ULONG_PTR p;

    if (base < 0x10000u) return 1;           /* NULL / low = not a pointer */
    for (p = base & ~(ULONG_PTR)0xFFF; p < need; p += 0x1000u) {
        if (VirtualQuery((LPCVOID)p, &mbi, sizeof mbi) == 0) return 1;
        if (mbi.State != MEM_COMMIT) return 1;
        if (mbi.Protect & (PAGE_NOACCESS | PAGE_GUARD)) return 1;
    }
    return 0;
}

int InstallPrmgGuard(void)   /* called from pmc_blackbox.c */
{
    DWORD oldp;
    unsigned char *p;
    unsigned char *q = (unsigned char *)PATCH_VA;
    int i;

    for (i = 0; i < (int)PATCH_LEN; i++) {
        if (q[i] != g_orig[i]) {
            pmc_log("prmg", "0x47AA5C guard NOT applied: bytes @0x%08X mismatch "
                    "(found %02X at +%d, expected %02X). Source [prmg].",
                    PATCH_VA, q[i], i, g_orig[i]);
            return 0;
        }
    }

    g_cave = (unsigned char *)VirtualAlloc(NULL, 96, MEM_COMMIT | MEM_RESERVE,
                                           PAGE_EXECUTE_READWRITE);
    if (!g_cave) {
        pmc_log("prmg", "0x47AA5C guard: VirtualAlloc(cave) failed.");
        return 0;
    }

    /* Build the cave (record+4 in ebx is validated via prmg_bad_handle, __cdecl,
     * which preserves ebx/esi/edi/ebp and returns 1 in eax when the handle is
     * NULL or unreadable):
     *   mov eax,[edi+0x14]     8B 47 14        ; original insn 1 (iVar3)
     *   mov ebx,[ebp+4]        8B 5D 04        ; record+4 (resource handle)
     *   push ecx / push edx    51 / 52         ; save caller-saved across the call
     *   push ebx               53              ; arg = record+4
     *   call prmg_bad_handle   E8 <rel32>      ; eax = bad?
     *   add esp,4              83 C4 04
     *   pop edx / pop ecx      5A / 59
     *   test eax,eax           85 C0
     *   jnz skip               75 0A           ; bad handle -> skip element
     *   mov eax,[edi+0x14]     8B 47 14        ; reload eax (call clobbered it)
     *   test eax,eax           85 C0           ; re-set ZF for je @0x47AA53
     *   jmp RESUME_VA          E9 <rel32>      ; resume normal element processing
     * skip:
     *   jmp SKIP_VA            E9 <rel32>      ; per-element increment (0x47ABA0)
     */
    p = g_cave;
    *p++=0x8B; *p++=0x47; *p++=0x14;            /* mov eax,[edi+0x14] */
    *p++=0x8B; *p++=0x5D; *p++=0x04;            /* mov ebx,[ebp+4]    */
    *p++=0x51; *p++=0x52;                       /* push ecx; push edx */
    *p++=0x53;                                  /* push ebx (arg)     */
    *p++=0xE8;                                  /* call prmg_bad_handle */
    {
        DWORD rel = (DWORD)(ULONG_PTR)&prmg_bad_handle - ((DWORD)(ULONG_PTR)p + 4);
        *p++ = (unsigned char)(rel & 0xFF);
        *p++ = (unsigned char)((rel >> 8) & 0xFF);
        *p++ = (unsigned char)((rel >> 16) & 0xFF);
        *p++ = (unsigned char)((rel >> 24) & 0xFF);
    }
    *p++=0x83; *p++=0xC4; *p++=0x04;            /* add esp,4          */
    *p++=0x5A; *p++=0x59;                       /* pop edx; pop ecx   */
    *p++=0x85; *p++=0xC0;                       /* test eax,eax       */
    *p++=0x75; *p++=0x0A;                       /* jnz skip (+0x0A)   */
    *p++=0x8B; *p++=0x47; *p++=0x14;            /* mov eax,[edi+0x14] */
    *p++=0x85; *p++=0xC0;                       /* test eax,eax       */
    *p++=0xE9;                                  /* jmp RESUME_VA      */
    {
        DWORD rel = RESUME_VA - ((DWORD)(ULONG_PTR)p + 4);
        *p++ = (unsigned char)(rel & 0xFF);
        *p++ = (unsigned char)((rel >> 8) & 0xFF);
        *p++ = (unsigned char)((rel >> 16) & 0xFF);
        *p++ = (unsigned char)((rel >> 24) & 0xFF);
    }
    /* skip: jmp SKIP_VA */
    *p++=0xE9;
    {
        DWORD rel = SKIP_VA - ((DWORD)(ULONG_PTR)p + 4);
        *p++ = (unsigned char)(rel & 0xFF);
        *p++ = (unsigned char)((rel >> 8) & 0xFF);
        *p++ = (unsigned char)((rel >> 16) & 0xFF);
        *p++ = (unsigned char)((rel >> 24) & 0xFF);
    }

    /* Patch PATCH_VA: jmp cave (E9 rel32) overwrites exactly 5 bytes. */
    if (!VirtualProtect((LPVOID)PATCH_VA, PATCH_LEN, PAGE_EXECUTE_READWRITE, &oldp)) {
        pmc_log("prmg", "0x47AA5C guard: VirtualProtect failed.");
        return 0;
    }
    {
        DWORD rel = (DWORD)(ULONG_PTR)g_cave - (PATCH_VA + 5);
        q[0] = 0xE9;
        q[1] = (unsigned char)(rel & 0xFF);
        q[2] = (unsigned char)((rel >> 8) & 0xFF);
        q[3] = (unsigned char)((rel >> 16) & 0xFF);
        q[4] = (unsigned char)((rel >> 24) & 0xFF);
    }
    VirtualProtect((LPVOID)PATCH_VA, PATCH_LEN, oldp, &oldp);
    FlushInstructionCache(GetCurrentProcess(), (LPVOID)PATCH_VA, PATCH_LEN);

    pmc_log("prmg", "0x47AA5C primitive-group guard ARMED @0x%08X -> cave %p: skips "
            "any PRMG element whose record+4 resource handle is NULL or unreadable "
            "(registry miss OR garbage element past an inflated count). Source [prmg].",
            PATCH_VA, (void *)g_cave);
    pmc_log_flush();
    return 1;
}

/* ---------------------------------------------------------------------------
 * Entity-binding guard for FUN_0047a6c0 (the twin PRMG render pass).
 *
 * FUN_0047a6c0 gates on record+0 (valid for the malformed element, so the
 * record+4 element-skip above doesn't fire here) and then walks the element's
 * entity-binding index array [elem+0x1b8], count [elem+0x1b4]:
 *     0x47A7C6  mov ecx,[esi+ebp]          ; binding index (garbage in the tail)
 *     0x47A7CD  imul ecx,ecx,0x190         ; * 0x190 (entity stride)
 *     0x47A7D3  add ecx,[edx+0x48]         ; + entity-pool base = entity ptr
 *     0x47A7D8  mov ax,[ecx+0xa0]          ; AV when ecx is wild (e.g. 0x806B2150)
 * The malformed element's binding array is over-long / under-filled (inflated
 * INFO count), so the tail indices are garbage -> wild entity ptr. Guard the
 * faulting read: if the entity ptr isn't readable, skip that one binding via the
 * loop's existing continue point 0x47A816 (same target the flag-test jne uses).
 * Skipping an unresolvable binding only omits a draw; it can't corrupt state.
 * ------------------------------------------------------------------------- */
#define EPATCH_VA   0x0047A7D8u   /* mov ax,word [ecx+0xa0] (7 bytes) */
#define ERESUME_VA  0x0047A7DFu   /* next instruction (shr ax,0xa) */
#define ESKIP_VA    0x0047A816u   /* loop continue (add ebx,1; add ebp,0x10; ...) */
#define EPATCH_LEN  7u

static const unsigned char g_eorig[EPATCH_LEN] = {0x66,0x8B,0x81,0xA0,0x00,0x00,0x00};
static unsigned char *g_ecave = NULL;

int InstallPrmgEntityGuard(void)   /* called from pmc_blackbox.c */
{
    DWORD oldp;
    unsigned char *p;
    unsigned char *q = (unsigned char *)EPATCH_VA;
    int i;

    for (i = 0; i < (int)EPATCH_LEN; i++) {
        if (q[i] != g_eorig[i]) {
            pmc_log("prmg", "0x47A7D8 entity guard NOT applied: bytes @0x%08X mismatch "
                    "(found %02X at +%d, expected %02X). Source [prmg].",
                    EPATCH_VA, q[i], i, g_eorig[i]);
            return 0;
        }
    }

    g_ecave = (unsigned char *)VirtualAlloc(NULL, 96, MEM_COMMIT | MEM_RESERVE,
                                            PAGE_EXECUTE_READWRITE);
    if (!g_ecave) {
        pmc_log("prmg", "0x47A7D8 entity guard: VirtualAlloc(cave) failed.");
        return 0;
    }

    /* Build the cave (ecx = entity ptr; prmg_bad_handle preserves ebx/esi/edi/ebp):
     *   push ecx               51              ; save entity ptr (call clobbers ecx)
     *   push edx               52              ; save caller-saved
     *   push ecx               51              ; arg = entity ptr
     *   call prmg_bad_handle   E8 <rel32>      ; eax = bad?
     *   add esp,4              83 C4 04
     *   pop edx                5A
     *   pop ecx                59              ; restore entity ptr
     *   test eax,eax           85 C0
     *   jnz skip               75 0C           ; unreadable -> skip this binding
     *   mov ax,[ecx+0xa0]      66 8B 81 A0 00 00 00   ; original read
     *   jmp ERESUME_VA         E9 <rel32>
     * skip:
     *   jmp ESKIP_VA           E9 <rel32>      ; loop continue (0x47A816)
     */
    p = g_ecave;
    *p++=0x51; *p++=0x52; *p++=0x51;            /* push ecx; push edx; push ecx */
    *p++=0xE8;                                  /* call prmg_bad_handle */
    {
        DWORD rel = (DWORD)(ULONG_PTR)&prmg_bad_handle - ((DWORD)(ULONG_PTR)p + 4);
        *p++=(unsigned char)(rel); *p++=(unsigned char)(rel>>8);
        *p++=(unsigned char)(rel>>16); *p++=(unsigned char)(rel>>24);
    }
    *p++=0x83; *p++=0xC4; *p++=0x04;            /* add esp,4 */
    *p++=0x5A; *p++=0x59;                       /* pop edx; pop ecx */
    *p++=0x85; *p++=0xC0;                       /* test eax,eax */
    *p++=0x75; *p++=0x0C;                       /* jnz skip (+0x0C) */
    *p++=0x66; *p++=0x8B; *p++=0x81; *p++=0xA0; *p++=0x00; *p++=0x00; *p++=0x00; /* mov ax,[ecx+0xa0] */
    *p++=0xE9;                                  /* jmp ERESUME_VA */
    {
        DWORD rel = ERESUME_VA - ((DWORD)(ULONG_PTR)p + 4);
        *p++=(unsigned char)(rel); *p++=(unsigned char)(rel>>8);
        *p++=(unsigned char)(rel>>16); *p++=(unsigned char)(rel>>24);
    }
    *p++=0xE9;                                  /* skip: jmp ESKIP_VA */
    {
        DWORD rel = ESKIP_VA - ((DWORD)(ULONG_PTR)p + 4);
        *p++=(unsigned char)(rel); *p++=(unsigned char)(rel>>8);
        *p++=(unsigned char)(rel>>16); *p++=(unsigned char)(rel>>24);
    }

    if (!VirtualProtect((LPVOID)EPATCH_VA, EPATCH_LEN, PAGE_EXECUTE_READWRITE, &oldp)) {
        pmc_log("prmg", "0x47A7D8 entity guard: VirtualProtect failed.");
        return 0;
    }
    {
        DWORD rel = (DWORD)(ULONG_PTR)g_ecave - (EPATCH_VA + 5);
        q[0]=0xE9;
        q[1]=(unsigned char)(rel); q[2]=(unsigned char)(rel>>8);
        q[3]=(unsigned char)(rel>>16); q[4]=(unsigned char)(rel>>24);
        q[5]=0x90; q[6]=0x90;
    }
    VirtualProtect((LPVOID)EPATCH_VA, EPATCH_LEN, oldp, &oldp);
    FlushInstructionCache(GetCurrentProcess(), (LPVOID)EPATCH_VA, EPATCH_LEN);

    pmc_log("prmg", "0x47A7D8 entity-binding guard ARMED @0x%08X -> cave %p: skips a "
            "PRMG binding whose entity ptr is unreadable (garbage index in an inflated "
            "binding array). Source [prmg].", EPATCH_VA, (void *)g_ecave);
    pmc_log_flush();
    return 1;
}
