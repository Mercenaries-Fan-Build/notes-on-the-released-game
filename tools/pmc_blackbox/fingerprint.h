#ifndef PMC_FINGERPRINT_H
#define PMC_FINGERPRINT_H

#include <windows.h>

/*
 * Game-artifact fingerprint.
 *
 * Hashes the mutable game-side artifacts (the running .exe, every .dll in the
 * game root, scripts/<asi>, and data/<wad>) with SHA-256 and writes one
 *   [blackbox] BUILD <kind>=<name> sha256=<hex> size=<bytes>
 * line per artifact to pmc_blackbox.log, so every run's log is SELF-ATTRIBUTING
 * (the metrics in loadprobe can be bound to the exact bytes that produced them,
 * with no reliance on file size/mtime, which change between observations).
 *
 * Files larger than the full-hash cap (vz.wad ~2.5 GB) are hashed as
 *   qsha256 = SHA-256(head 8 MiB || tail 8 MiB || u64 size)
 * which is reproducible and change-detecting without reading multiple GiB at
 * every boot. The hash type token in the log (`sha256=` vs `qsha256=`) tells the
 * reader which was used.
 *
 * Heavy (file I/O + hashing): pmc_start_fingerprint spawns a worker thread, so
 * this never runs under the DllMain loader lock and never blocks game boot.
 */
void pmc_start_fingerprint(HINSTANCE self);

#endif /* PMC_FINGERPRINT_H */
