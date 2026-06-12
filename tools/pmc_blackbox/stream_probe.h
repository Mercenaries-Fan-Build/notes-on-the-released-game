#ifndef STREAM_PROBE_H
#define STREAM_PROBE_H

/* Install the streaming-stall probe (MinHook detour on the promotion gate).
 * Returns 1 on success, 0 on failure. Safe to call once after MinHook init. */
int InstallStreamProbe(void);

#endif /* STREAM_PROBE_H */
