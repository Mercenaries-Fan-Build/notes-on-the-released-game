/**
 * crash_handler.c — capture the faulting site when the game dies.
 *
 * The retail EXE has no usable unhandled-exception path: on a fault the process
 * just vanishes, leaving no record of WHERE it crashed. This installs two nets so
 * any fatal fault is written to pmc_blackbox.log (source [crash]) before the
 * process goes down — the faulting EIP, the exception code, the AV target
 * address, the full integer register file, and the exe-range return addresses on
 * the stack (a poor-man's call stack).
 *
 *   - A Vectored Exception Handler catches the fault FIRST-chance (before any
 *     frame SEH), so it fires even if something later swallows the exception.
 *   - SetUnhandledExceptionFilter catches the classic last-chance fatal path.
 *
 * Safe by construction: faulting EIPs are de-duplicated (a repeating fault logs
 * once), a reentrancy guard prevents recursion if logging itself faults, and the
 * stack walk is skipped for stack-overflow exceptions (where touching the stack
 * would re-fault). Only "severe" codes are logged via the VEH so ordinary
 * first-chance noise is ignored.
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

extern void pmc_log(const char *source, const char *fmt, ...);
extern void pmc_log_flush(void);

#define CRASH_SEEN_N 32
static DWORD g_seen[CRASH_SEEN_N];
static int   g_seenCount;
static LONG  g_inHandler;            /* reentrancy guard */

static int crash_seen(DWORD addr)
{
    int i;
    for (i = 0; i < g_seenCount; i++)
        if (g_seen[i] == addr)
            return 1;
    if (g_seenCount < CRASH_SEEN_N)
        g_seen[g_seenCount++] = addr;
    return 0;
}

static int is_severe(DWORD code)
{
    switch (code) {
    case EXCEPTION_ACCESS_VIOLATION:
    case EXCEPTION_ILLEGAL_INSTRUCTION:
    case EXCEPTION_PRIV_INSTRUCTION:
    case EXCEPTION_STACK_OVERFLOW:
    case EXCEPTION_ARRAY_BOUNDS_EXCEEDED:
    case EXCEPTION_INT_DIVIDE_BY_ZERO:
    case EXCEPTION_IN_PAGE_ERROR:
    case 0xC0000409UL:              /* __fastfail / stack-cookie */
        return 1;
    default:
        return 0;
    }
}

static void log_exception(EXCEPTION_POINTERS *ep, const char *via)
{
    EXCEPTION_RECORD *er = ep->ExceptionRecord;
    CONTEXT *cx = ep->ContextRecord;
    DWORD eip = (DWORD)(ULONG_PTR)er->ExceptionAddress;

    if (InterlockedExchange(&g_inHandler, 1))   /* logging itself faulted */
        return;
    if (crash_seen(eip)) {                       /* this site already logged */
        InterlockedExchange(&g_inHandler, 0);
        return;
    }

    pmc_log("crash", "==== %s EXCEPTION %08lX @ EIP=%08lX (flags=%lX) ====",
            via, er->ExceptionCode, eip, er->ExceptionFlags);
    if (er->ExceptionCode == EXCEPTION_ACCESS_VIOLATION && er->NumberParameters >= 2) {
        DWORD kind = (DWORD)er->ExceptionInformation[0];
        pmc_log("crash", "  AV %s target=%08lX",
                kind == 1 ? "WRITE" : kind == 8 ? "EXEC" : "READ",
                (DWORD)er->ExceptionInformation[1]);
    }
    pmc_log("crash", "  EAX=%08lX ECX=%08lX EDX=%08lX EBX=%08lX",
            cx->Eax, cx->Ecx, cx->Edx, cx->Ebx);
    pmc_log("crash", "  ESP=%08lX EBP=%08lX ESI=%08lX EDI=%08lX",
            cx->Esp, cx->Ebp, cx->Esi, cx->Edi);

    /* Shallow stack walk: exe-range return addresses just above ESP. Skipped on
     * stack overflow, where reading the stack would re-fault on the guard page. */
    if (er->ExceptionCode != EXCEPTION_STACK_OVERFLOW) {
        const DWORD *sp = (const DWORD *)cx->Esp;
        int i, found = 0;
        for (i = 0; i < 160 && found < 16; i++) {
            DWORD v = sp[i];
            if (v >= 0x00401000UL && v < 0x00C00000UL) {
                pmc_log("crash", "  stk+%03X = %08lX", i * 4, v);
                found++;
            }
        }
    }
    pmc_log_flush();
    InterlockedExchange(&g_inHandler, 0);
}

static LONG CALLBACK VehHandler(EXCEPTION_POINTERS *ep)
{
    if (is_severe(ep->ExceptionRecord->ExceptionCode))
        log_exception(ep, "VEH");
    return EXCEPTION_CONTINUE_SEARCH;   /* don't alter behavior — just record */
}

static LONG WINAPI UnhandledFilter(EXCEPTION_POINTERS *ep)
{
    log_exception(ep, "UNHANDLED");
    return EXCEPTION_EXECUTE_HANDLER;   /* terminate; we've recorded it */
}

void InstallCrashHandler(void)
{
    AddVectoredExceptionHandler(1, VehHandler);   /* 1 = first in the VEH chain */
    SetUnhandledExceptionFilter(UnhandledFilter);
    pmc_log("crash", "Crash handler armed (VEH + UnhandledExceptionFilter) — "
            "faults logged to source [crash].");
    pmc_log_flush();
}
