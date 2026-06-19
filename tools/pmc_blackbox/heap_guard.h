#ifndef HEAP_GUARD_H
#define HEAP_GUARD_H

#include <windows.h>

/* Install the heap-history tracker: MinHook detours on the hkThreadMemory
 * allocator (0x0088CB70) and free (0x0088CBD0), recording {op,ptr,size,caller}
 * into a lock-free ring. Observation-only (no heap mutation). Returns 1 on
 * success, 0 if disabled (PMC_NO_HEAP_GUARD) or hook setup failed. */
int InstallHeapGuard(void);

/* Crash-time: scan the ring for records touching `addr` and log the covering
 * block (+ its allocator caller), any use-after-free, and the nearest preceding
 * block (overflow source). No-op if the tracker isn't enabled. */
void HeapGuardQuery(DWORD addr);

#endif /* HEAP_GUARD_H */
