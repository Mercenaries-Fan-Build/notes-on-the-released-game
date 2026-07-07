/**
 * winsock_redirect.asi — Redirect Mercenaries 2's EA network traffic to Modkit
 *
 * The retail game reaches dead EA hosts (fesl.ea.com, messaging.ea.com,
 * locate.madserver.net) using hardcoded hostnames AND, in some paths, hardcoded
 * IPs. This plugin hooks the Winsock2 import table so that:
 *
 *   - gethostbyname / getaddrinfo  : EA hostnames resolve to the Modkit IP.
 *   - connect / WSAConnect         : connections to public IPs are rewritten to
 *                                    the Modkit IP (port preserved), catching
 *                                    hardcoded IPs the name hooks miss.
 *   - GetProcAddress               : late-bound Winsock lookups get our hooks.
 *
 * The destination *port* is preserved, so coopserver can keep its stable
 * port -> protocol mapping and just auto-detect per connection.
 *
 * Config (optional): scripts/winsock_redirect.ini
 *   [redirect]
 *   modkit_ip=192.168.1.50      ; where to send EA traffic (default 127.0.0.1)
 *   redirect_private=0          ; 1 = also redirect LAN/private IPs
 *
 * A log of every resolved host + redirected connect is written next to the
 * .asi (winsock_redirect.log) — a second capture vantage point that also
 * reveals the real FESL port to configure coopserver with.
 *
 * Build:   make mingw
 * Install: copy winsock_redirect.asi (+ optional .ini) to <game>/scripts/
 */

#define WIN32_LEAN_AND_MEAN
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

/* --- Global state --- */

static HMODULE g_hModule = NULL;
static char g_modkit_ip[64] = "127.0.0.1";
static DWORD g_modkit_addr = 0;          /* network byte order */
static int  g_redirect_private = 0;

/* Cert-clock spoof: EA's FESL cert (fesl.ea.com) expired 2024-10-25, so the
 * game's OpenSSL X509 date check rejects it now. We hook the CRT _time64 (what
 * X509_cmp_time calls) to report a date inside the cert window (default
 * 2020-06-01 = 1590969600) so the genuine cert validates. */
static int     g_faketime_enabled = 1;
static __int64 g_faketime = 1590969600LL;
static __int64 (*real__time64)(__int64 *) = NULL;  /* __cdecl, not WINAPI */

/* Saved originals (set from the IAT slot we overwrite). */
static struct hostent* (WINAPI *real_gethostbyname)(const char*) = NULL;
static int (WINAPI *real_getaddrinfo)(const char*, const char*,
                                      const struct addrinfo*, struct addrinfo**) = NULL;
static int (WINAPI *real_connect)(SOCKET, const struct sockaddr*, int) = NULL;
static int (WINAPI *real_WSAConnect)(SOCKET, const struct sockaddr*, int,
                                     LPWSABUF, LPWSABUF, LPQOS, LPQOS) = NULL;
static FARPROC (WINAPI *real_GetProcAddress)(HMODULE, LPCSTR) = NULL;

/* --- Logging (mirrors net_hooks.asi) --- */

static HANDLE g_logFile = INVALID_HANDLE_VALUE;

static void LogInit(void) {
    char path[MAX_PATH];
    char *dot;
    GetModuleFileNameA(g_hModule, path, MAX_PATH);
    dot = strrchr(path, '.');
    if (dot) strcpy(dot, ".log"); else strcat(path, ".log");
    g_logFile = CreateFileA(path, GENERIC_WRITE, FILE_SHARE_READ,
                            NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
}

static void Log(const char *fmt, ...) {
    char buf[1024];
    int len;
    va_list ap;
    DWORD written;
    va_start(ap, fmt);
    len = wvsprintfA(buf, fmt, ap);
    va_end(ap);
    if (len <= 0) return;
    if (g_logFile != INVALID_HANDLE_VALUE) {
        buf[len] = '\r'; buf[len + 1] = '\n';
        WriteFile(g_logFile, buf, len + 2, &written, NULL);
        FlushFileBuffers(g_logFile);
    }
}

static void LogClose(void) {
    if (g_logFile != INVALID_HANDLE_VALUE) {
        CloseHandle(g_logFile);
        g_logFile = INVALID_HANDLE_VALUE;
    }
}

/* --- Config --- */

static void LoadConfig(void) {
    char ini[MAX_PATH];
    char *dot;
    GetModuleFileNameA(g_hModule, ini, MAX_PATH);
    dot = strrchr(ini, '.');
    if (dot) strcpy(dot, ".ini"); else strcat(ini, ".ini");

    GetPrivateProfileStringA("redirect", "modkit_ip", "127.0.0.1",
                             g_modkit_ip, sizeof(g_modkit_ip), ini);
    g_redirect_private = GetPrivateProfileIntA("redirect", "redirect_private", 0, ini);
    g_modkit_addr = inet_addr(g_modkit_ip);

    g_faketime_enabled = GetPrivateProfileIntA("cert", "faketime_enabled", 1, ini);
    {
        /* epoch seconds; 0 keeps the built-in default (2020-06-01). */
        int epoch = GetPrivateProfileIntA("cert", "faketime_epoch", 0, ini);
        if (epoch > 0) g_faketime = (__int64)epoch;
    }
    Log("config: modkit_ip=%s redirect_private=%d faketime_enabled=%d faketime=%lld (ini=%s)",
        g_modkit_ip, g_redirect_private, g_faketime_enabled, g_faketime, ini);
}

/* --- Match helpers --- */

static int IsEaHost(const char* name) {
    if (!name) return 0;
    /* Case-insensitive substring match on the known EA service domains. */
    char low[256];
    size_t i;
    for (i = 0; name[i] && i < sizeof(low) - 1; i++) {
        char c = name[i];
        low[i] = (c >= 'A' && c <= 'Z') ? (char)(c + 32) : c;
    }
    low[i] = 0;
    return strstr(low, "ea.com") != NULL
        || strstr(low, "madserver.net") != NULL
        || strstr(low, "eagames") != NULL;
}

static int IsPrivateOrLocal(DWORD addr_net) {
    /* addr_net is network byte order; inspect the high octet first. */
    unsigned char a = (unsigned char)(addr_net & 0xFF);          /* first octet */
    unsigned char b = (unsigned char)((addr_net >> 8) & 0xFF);   /* second octet */
    if (a == 127) return 1;                       /* loopback */
    if (a == 10) return 1;                         /* 10.0.0.0/8 */
    if (a == 192 && b == 168) return 1;            /* 192.168.0.0/16 */
    if (a == 172 && b >= 16 && b <= 31) return 1;  /* 172.16.0.0/12 */
    if (a == 169 && b == 254) return 1;            /* link-local */
    if (a == 0) return 1;                          /* unspecified */
    return 0;
}

static int ShouldRedirect(DWORD addr_net) {
    if (addr_net == g_modkit_addr) return 0;       /* already us */
    if (IsPrivateOrLocal(addr_net)) return g_redirect_private;
    return 1;                                       /* public internet -> redirect */
}

/* --- Hooks --- */

static struct hostent* WINAPI Hook_gethostbyname(const char* name) {
    if (IsEaHost(name)) {
        Log("gethostbyname(%s) -> %s", name, g_modkit_ip);
        return real_gethostbyname(g_modkit_ip);
    }
    if (name) Log("gethostbyname(%s) [passthrough]", name);
    return real_gethostbyname(name);
}

static int WINAPI Hook_getaddrinfo(const char* node, const char* service,
                                   const struct addrinfo* hints,
                                   struct addrinfo** res) {
    if (IsEaHost(node)) {
        Log("getaddrinfo(%s,%s) -> %s", node, service ? service : "", g_modkit_ip);
        return real_getaddrinfo(g_modkit_ip, service, hints, res);
    }
    if (node) Log("getaddrinfo(%s,%s) [passthrough]", node, service ? service : "");
    return real_getaddrinfo(node, service, hints, res);
}

static void RewriteIfNeeded(const struct sockaddr* name, int namelen,
                            struct sockaddr_in* out, const struct sockaddr** use,
                            int* uselen, const char* who) {
    *use = name;
    *uselen = namelen;
    if (name && name->sa_family == AF_INET && namelen >= (int)sizeof(struct sockaddr_in)) {
        const struct sockaddr_in* in = (const struct sockaddr_in*)name;
        int port = ntohs(in->sin_port);
        if (ShouldRedirect(in->sin_addr.s_addr)) {
            *out = *in;
            out->sin_addr.s_addr = g_modkit_addr;
            *use = (const struct sockaddr*)out;
            *uselen = sizeof(struct sockaddr_in);
            Log("%s %s:%d -> %s:%d", who, inet_ntoa(in->sin_addr), port, g_modkit_ip, port);
        } else {
            Log("%s %s:%d [passthrough]", who, inet_ntoa(in->sin_addr), port);
        }
    }
}

static int WINAPI Hook_connect(SOCKET s, const struct sockaddr* name, int namelen) {
    struct sockaddr_in red;
    const struct sockaddr* use; int uselen;
    RewriteIfNeeded(name, namelen, &red, &use, &uselen, "connect");
    return real_connect(s, use, uselen);
}

static int WINAPI Hook_WSAConnect(SOCKET s, const struct sockaddr* name, int namelen,
                                  LPWSABUF cd, LPWSABUF cbd, LPQOS sqos, LPQOS gqos) {
    struct sockaddr_in red;
    const struct sockaddr* use; int uselen;
    RewriteIfNeeded(name, namelen, &red, &use, &uselen, "WSAConnect");
    return real_WSAConnect(s, use, uselen, cd, cbd, sqos, gqos);
}

/* CRT _time64 (__cdecl) — report a date inside the FESL cert's validity window.
 * We shift real time back by a fixed offset (anchored so "now" ~= g_faketime)
 * rather than freezing it, so the clock still advances and game timers behave. */
static __int64 g_time_offset = 0;
static int g_time_offset_init = 0;
static __int64 Hook__time64(__int64 *dest) {
    __int64 r = g_faketime;
    if (real__time64) {
        __int64 now = real__time64(0);
        if (!g_time_offset_init) { g_time_offset = now - g_faketime; g_time_offset_init = 1; }
        r = now - g_time_offset;
    }
    if (dest) *dest = r;
    return r;
}

static FARPROC WINAPI Hook_GetProcAddress(HMODULE hMod, LPCSTR proc) {
    FARPROC orig = real_GetProcAddress(hMod, proc);
    /* Ordinals come in as values <= 0xFFFF — ignore those. */
    if (orig && proc && ((DWORD_PTR)proc > 0xFFFF)) {
        if (!lstrcmpiA(proc, "gethostbyname")) {
            if (!real_gethostbyname) real_gethostbyname = (void*)orig;
            return (FARPROC)Hook_gethostbyname;
        }
        if (!lstrcmpiA(proc, "getaddrinfo")) {
            if (!real_getaddrinfo) real_getaddrinfo = (void*)orig;
            return (FARPROC)Hook_getaddrinfo;
        }
        if (!lstrcmpiA(proc, "connect")) {
            if (!real_connect) real_connect = (void*)orig;
            return (FARPROC)Hook_connect;
        }
        if (!lstrcmpiA(proc, "WSAConnect")) {
            if (!real_WSAConnect) real_WSAConnect = (void*)orig;
            return (FARPROC)Hook_WSAConnect;
        }
    }
    return orig;
}

/* --- IAT hook installer ---
 *
 * Mercenaries 2 imports Winsock BY ORDINAL (ws2_32: connect=4, gethostbyname=52;
 * the import names show as "<none>"), so a by-name match alone hooks nothing.
 * HookIAT matches by ordinal when `ordinal` != 0, otherwise by name. The
 * ws2_32/wsock32 ordinals are Microsoft-assigned and stable across Windows. */

static int HookIAT(const char* dll, const char* func, WORD ordinal,
                   void* hook, void** orig) {
    HMODULE base = GetModuleHandleA(NULL);          /* the game EXE */
    BYTE* image = (BYTE*)base;
    PIMAGE_DOS_HEADER dos = (PIMAGE_DOS_HEADER)image;
    PIMAGE_NT_HEADERS nt = (PIMAGE_NT_HEADERS)(image + dos->e_lfanew);
    DWORD impRVA = nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress;
    if (!impRVA) return 0;

    PIMAGE_IMPORT_DESCRIPTOR imp = (PIMAGE_IMPORT_DESCRIPTOR)(image + impRVA);
    for (; imp->Name; imp++) {
        const char* dllname = (const char*)(image + imp->Name);
        if (lstrcmpiA(dllname, dll) != 0) continue;

        PIMAGE_THUNK_DATA names = (PIMAGE_THUNK_DATA)(image + (imp->OriginalFirstThunk
                                                              ? imp->OriginalFirstThunk
                                                              : imp->FirstThunk));
        PIMAGE_THUNK_DATA iat = (PIMAGE_THUNK_DATA)(image + imp->FirstThunk);
        for (; names->u1.AddressOfData; names++, iat++) {
            int match = 0;
            if (names->u1.Ordinal & IMAGE_ORDINAL_FLAG) {
                if (ordinal && (WORD)(names->u1.Ordinal & 0xFFFF) == ordinal) match = 1;
            } else if (func) {
                PIMAGE_IMPORT_BY_NAME ibn = (PIMAGE_IMPORT_BY_NAME)(image + names->u1.AddressOfData);
                if (lstrcmpiA((const char*)ibn->Name, func) == 0) match = 1;
            }
            if (!match) continue;

            DWORD oldProtect;
            void** slot = (void**)&iat->u1.Function;
            if (orig && *orig == NULL) *orig = *slot;       /* save real fn */
            if (!VirtualProtect(slot, sizeof(void*), PAGE_READWRITE, &oldProtect)) {
                Log("IAT %s!%s(ord %u): VirtualProtect failed (err=%d)",
                    dll, func ? func : "?", ordinal, GetLastError());
                return 0;
            }
            *slot = hook;
            VirtualProtect(slot, sizeof(void*), oldProtect, &oldProtect);
            Log("IAT %s!%s(ord %u) hooked (slot=%p)", dll, func ? func : "?", ordinal, (void*)slot);
            return 1;
        }
    }
    return 0;
}

/* --- DLL entry point --- */

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
    (void)lpvReserved;
    if (fdwReason == DLL_PROCESS_ATTACH) {
        g_hModule = (HMODULE)hinstDLL;
        DisableThreadLibraryCalls(hinstDLL);
        LogInit();
        Log("winsock_redirect.asi loaded (PID %d)", GetCurrentProcessId());
        LoadConfig();

        /* Mercenaries 2 imports these by ORDINAL (ws2_32: connect=4,
           gethostbyname=52). wsock32 mirrors the same low ordinals. We also try
           by-name for getaddrinfo/WSAConnect in case another module uses them. */
        int n = 0;
        n += HookIAT("ws2_32.dll",  "gethostbyname", 52, (void*)Hook_gethostbyname, (void**)&real_gethostbyname);
        n += HookIAT("ws2_32.dll",  "connect",        4, (void*)Hook_connect,       (void**)&real_connect);
        n += HookIAT("ws2_32.dll",  "getaddrinfo",    0, (void*)Hook_getaddrinfo,   (void**)&real_getaddrinfo);
        n += HookIAT("ws2_32.dll",  "WSAConnect",     0, (void*)Hook_WSAConnect,    (void**)&real_WSAConnect);
        n += HookIAT("wsock32.dll", "gethostbyname", 52, (void*)Hook_gethostbyname, (void**)&real_gethostbyname);
        n += HookIAT("wsock32.dll", "connect",        4, (void*)Hook_connect,       (void**)&real_connect);
        n += HookIAT("kernel32.dll", "GetProcAddress", 0, (void*)Hook_GetProcAddress, (void**)&real_GetProcAddress);

        /* Cert-clock spoof so the expired EA FESL cert validates. */
        if (g_faketime_enabled) {
            int t = HookIAT("msvcr80.dll", "_time64", 0, (void*)Hook__time64, (void**)&real__time64);
            Log("cert clock spoof: _time64 hook %s (-> %lld)", t ? "OK" : "NOT FOUND", g_faketime);
            n += t;
        }

        /* If GetProcAddress wasn't imported by the EXE, fall back to the real one
           so our GetProcAddress hook (if ws2_32 binds late) still works. */
        if (!real_GetProcAddress)
            real_GetProcAddress = (FARPROC (WINAPI *)(HMODULE, LPCSTR))GetProcAddress;

        Log("install complete — %d IAT slots hooked", n);
    } else if (fdwReason == DLL_PROCESS_DETACH) {
        Log("winsock_redirect.asi unloaded");
        LogClose();
    }
    return TRUE;
}
