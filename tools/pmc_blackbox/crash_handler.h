#ifndef CRASH_HANDLER_H
#define CRASH_HANDLER_H

/* Install VEH + unhandled-exception filter that log the faulting site (EIP,
 * code, AV target, registers, exe-range stack) to pmc_blackbox.log [crash]. */
void InstallCrashHandler(void);

#endif /* CRASH_HANDLER_H */
