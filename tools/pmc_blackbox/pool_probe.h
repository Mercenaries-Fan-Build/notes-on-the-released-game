#ifndef POOL_PROBE_H
#define POOL_PROBE_H

/* Install the render-instance pool drain tracer (poll-only background thread,
 * no engine detour). Logs the 5120-cell pool's free-count trajectory so the
 * world-load 0x4CC064 exhaustion can be classified as T1 (converter inflated
 * count -> burst drain) vs T2 (legit budget -> gradual drain).
 * Returns 1 on success. Safe to call once at startup. */
int InstallPoolProbe(void);

/* Install the render-instance pool overflow FIX: a MinHook detour on the pop
 * FUN_004cc030 that hands back a fresh 0x54 cell when the 5120-cell free-list is
 * empty, instead of the NULL fallback that crashes at 0x4CC064. Lets the DLC
 * world load past the 5120 distinct-texture-component cap. Returns 1 on success.
 * Opt out with -DPMC_DISABLE_POOL_OVERFLOW_FIX. */
int InstallPoolOverflowFix(void);

#endif /* POOL_PROBE_H */
