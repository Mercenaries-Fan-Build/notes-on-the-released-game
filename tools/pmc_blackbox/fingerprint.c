/*
 * fingerprint.c — self-attributing run fingerprint.
 *
 * Writes [blackbox] BUILD lines naming the SHA-256 of every mutable game-side
 * artifact, so a pmc_blackbox.log can be bound to the exact bytes that produced
 * it. See fingerprint.h. SHA-256 is computed with the Windows CNG (BCrypt) API,
 * streamed in 1 MiB chunks (no whole-file buffering), on a worker thread.
 */

#include <windows.h>
#include <bcrypt.h>
#include <stdlib.h>
#include <string.h>

#include "fingerprint.h"

extern void pmc_log(const char *source, const char *fmt, ...);

/* Files <= this are fully hashed; larger ones use the head+tail+size quick hash
 * (qsha256). 1 GiB covers the exe, every dll, vz-patch.wad and English.wad; only
 * the ~2.5 GiB base vz.wad falls into the quick path. */
#define FP_FULL_HASH_MAX  (1024ULL * 1024 * 1024)
#define FP_QUICK_EDGE     (8ULL * 1024 * 1024)   /* head & tail bytes hashed */
#define FP_CHUNK          (1024 * 1024)          /* streaming read size */

static const char FP_HEX[] = "0123456789abcdef";

/* u64 -> decimal string (wvsprintfA used by pmc_log has no 64-bit conversion). */
static void fp_u64_to_str(unsigned long long v, char *out) {
    char tmp[24];
    int i = 0, j = 0;
    if (v == 0) { out[0] = '0'; out[1] = '\0'; return; }
    while (v) { tmp[i++] = (char)('0' + (int)(v % 10)); v /= 10; }
    while (i) out[j++] = tmp[--i];
    out[j] = '\0';
}

/* Hash [off, off+len) of an open file into hh. Returns 1 on success. */
static int fp_hash_region(BCRYPT_HASH_HANDLE hh, HANDLE f,
                          unsigned long long off, unsigned long long len,
                          unsigned char *buf) {
    LARGE_INTEGER li;
    unsigned long long remaining = len;
    li.QuadPart = (LONGLONG)off;
    if (!SetFilePointerEx(f, li, NULL, FILE_BEGIN)) return 0;
    while (remaining > 0) {
        DWORD want = (DWORD)(remaining < (unsigned long long)FP_CHUNK
                             ? remaining : (unsigned long long)FP_CHUNK);
        DWORD got = 0;
        if (!ReadFile(f, buf, want, &got, NULL)) return 0;
        if (got == 0) break;
        if (BCryptHashData(hh, buf, got, 0) != 0) return 0;
        remaining -= got;
    }
    return 1;
}

/* SHA-256 (or quick head+tail+size) of a file -> 64-char lowercase hex.
 * out_hex must be >= 65 bytes. Returns 1 on success. */
static int fp_hash_file(const char *path, char *out_hex,
                        unsigned long long *out_size, int *out_quick) {
    WIN32_FILE_ATTRIBUTE_DATA fad;
    HANDLE f;
    BCRYPT_ALG_HANDLE alg = NULL;
    BCRYPT_HASH_HANDLE hh = NULL;
    unsigned char *obj = NULL;
    unsigned char *buf = NULL;
    unsigned char hash[32];
    unsigned long long size;
    DWORD objlen = 0, cb = 0;
    int ok = 0, i;

    *out_quick = 0;
    *out_size = 0;
    if (!GetFileAttributesExA(path, GetFileExInfoStandard, &fad)) return 0;
    size = ((unsigned long long)fad.nFileSizeHigh << 32) | fad.nFileSizeLow;
    *out_size = size;

    f = CreateFileA(path, GENERIC_READ,
                    FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                    NULL, OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, NULL);
    if (f == INVALID_HANDLE_VALUE) return 0;

    do {
        if (BCryptOpenAlgorithmProvider(&alg, BCRYPT_SHA256_ALGORITHM, NULL, 0) != 0) break;
        if (BCryptGetProperty(alg, BCRYPT_OBJECT_LENGTH,
                              (PUCHAR)&objlen, sizeof(objlen), &cb, 0) != 0) break;
        obj = (unsigned char *)malloc(objlen);
        buf = (unsigned char *)malloc(FP_CHUNK);
        if (!obj || !buf) break;
        if (BCryptCreateHash(alg, &hh, obj, objlen, NULL, 0, 0) != 0) break;

        if (size <= FP_FULL_HASH_MAX) {
            if (!fp_hash_region(hh, f, 0, size, buf)) break;
        } else {
            *out_quick = 1;
            if (!fp_hash_region(hh, f, 0, FP_QUICK_EDGE, buf)) break;
            if (!fp_hash_region(hh, f, size - FP_QUICK_EDGE, FP_QUICK_EDGE, buf)) break;
            if (BCryptHashData(hh, (PUCHAR)&size, sizeof(size), 0) != 0) break;
        }
        if (BCryptFinishHash(hh, hash, sizeof(hash), 0) != 0) break;
        for (i = 0; i < 32; i++) {
            out_hex[i * 2]     = FP_HEX[hash[i] >> 4];
            out_hex[i * 2 + 1] = FP_HEX[hash[i] & 0xF];
        }
        out_hex[64] = '\0';
        ok = 1;
    } while (0);

    if (hh)  BCryptDestroyHash(hh);
    if (alg) BCryptCloseAlgorithmProvider(alg, 0);
    if (obj) free(obj);
    if (buf) free(buf);
    CloseHandle(f);
    return ok;
}

static void fp_log_one(const char *kind, const char *name, const char *path) {
    char hex[65];
    char szs[24];
    unsigned long long size = 0;
    int quick = 0;
    if (fp_hash_file(path, hex, &size, &quick)) {
        fp_u64_to_str(size, szs);
        pmc_log("blackbox", "  BUILD %s=%s %s=%s size=%s",
                kind, name, quick ? "qsha256" : "sha256", hex, szs);
    } else {
        pmc_log("blackbox", "  BUILD %s=%s sha256=UNREADABLE", kind, name);
    }
}

/* Hash every <folder><glob> file as <kind>. skip_full (optional) is skipped
 * (used to avoid double-logging the self dll). folder must end with '\\'. */
static void fp_enum(const char *folder, const char *glob, const char *kind,
                    const char *skip_full) {
    char pattern[MAX_PATH];
    char full[MAX_PATH];
    WIN32_FIND_DATAA fd;
    HANDLE h;
    wsprintfA(pattern, "%s%s", folder, glob);
    h = FindFirstFileA(pattern, &fd);
    if (h == INVALID_HANDLE_VALUE) return;
    do {
        if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) continue;
        wsprintfA(full, "%s%s", folder, fd.cFileName);
        if (skip_full && lstrcmpiA(full, skip_full) == 0) continue;
        fp_log_one(kind, fd.cFileName, full);
    } while (FindNextFileA(h, &fd));
    FindClose(h);
}

static void pmc_log_game_fingerprint(HINSTANCE self) {
    char exepath[MAX_PATH];
    char dir[MAX_PATH];
    char dllpath[MAX_PATH];
    char folder[MAX_PATH];
    char *sep;
    const char *exename;
    const char *dllname;

    /* exe full path + name; `dir` is exepath with the filename stripped (keeps
     * the trailing backslash) so it can be reused as the game-root folder. */
    GetModuleFileNameA(NULL, exepath, MAX_PATH);
    {
        char *esep = strrchr(exepath, '\\');
        exename = esep ? esep + 1 : exepath;
    }
    lstrcpynA(dir, exepath, MAX_PATH);
    sep = strrchr(dir, '\\');
    if (sep) *(sep + 1) = '\0';        /* dir now ends with '\\' */

    /* self dll full path + name */
    GetModuleFileNameA(self, dllpath, MAX_PATH);
    {
        char *dsep = strrchr(dllpath, '\\');
        dllname = dsep ? dsep + 1 : dllpath;
    }

    pmc_log("blackbox", "  ---- game fingerprint (sha256; qsha256=head+tail+size for >1GiB) ----");
    fp_log_one("exe", exename, exepath);
    fp_log_one("dll", dllname, dllpath);

    /* every dll in the game root (skip the self dll, already logged) */
    fp_enum(dir, "*.dll", "dll", dllpath);

    /* ASI plugins */
    wsprintfA(folder, "%sscripts\\", dir);
    fp_enum(folder, "*.asi", "asi", NULL);

    /* data WADs */
    wsprintfA(folder, "%sdata\\", dir);
    fp_enum(folder, "*.wad", "wad", NULL);

    pmc_log("blackbox", "  ---- end fingerprint ----");
}

static DWORD WINAPI fp_thread(LPVOID p) {
    pmc_log_game_fingerprint((HINSTANCE)p);
    return 0;
}

void pmc_start_fingerprint(HINSTANCE self) {
    HANDLE t = CreateThread(NULL, 0, fp_thread, (LPVOID)self, 0, NULL);
    if (t) CloseHandle(t);
}
