#!/usr/bin/env python3
"""Locate the statically-linked OpenSSL 0.9.8 SSLv3 SSL_METHOD tables in a
Mercenaries 2 PE and report the ssl_connect/ssl_read/ssl_write function pointers.

This is the deterministic anchor for the FESL "modern TLS + accept-self-signed"
detour: patch the three fn-pointers in the SSLv3_client_method table in place and
every SSL_connect/SSL_read/SSL_write dispatches (via s->method->...) to the shim.

Cross-build note: OpenSSL .text/Stext VAs differ per build, so re-run this against
whatever exe ships. Only the Srdata string pool (".\\ssl\\s3_clnt.c") is a stable
cross-build anchor. See docs/reverse_engineer/networking_code_map.md §7.6/§7.7.

Usage:  python scripts/ssl_method_scan.py <path-to-exe>
Verified target: output/_ghidra/securom_dump/mercs2_nodrm_v3.exe
  SSLv3_client_method table @ 0x0237ee88  (Sdata, writable)
    +0x14 ssl_connect = 0x01e1a09b (ssl3_connect)
    +0x18 ssl_read    = 0x01e1cfb0 (ssl3_read)
    +0x20 ssl_write   = 0x01e1ce94 (ssl3_write)
"""
import struct, sys

# OpenSSL 0.9.8 ssl_method_st DWORD indices (after the version field)
OFF = {"ssl_new":0,"ssl_clear":1,"ssl_free":2,"ssl_accept":3,"ssl_connect":4,
       "ssl_read":5,"ssl_peek":6,"ssl_write":7,"ssl_shutdown":8}

def load(path):
    d = open(path, "rb").read()
    pe = struct.unpack_from("<I", d, 0x3c)[0]
    assert d[pe:pe+4] == b"PE\0\0", "not a PE"
    nsec = struct.unpack_from("<H", d, pe+6)[0]
    optsz = struct.unpack_from("<H", d, pe+20)[0]
    imgbase = struct.unpack_from("<I", d, pe+0x34)[0]
    secoff = pe + 24 + optsz
    secs = []
    for i in range(nsec):
        o = secoff + i*40
        name = d[o:o+8].rstrip(b"\0").decode("latin1")
        vsz, va, rsz, rptr = struct.unpack_from("<IIII", d, o+8)
        chars = struct.unpack_from("<I", d, o+36)[0]
        secs.append((name, va, vsz, rptr, rsz, chars))
    return d, imgbase, secs

def sect_of(secs, imgbase, va):
    rva = va - imgbase
    for name, sva, vsz, rptr, rsz, ch in secs:
        if sva <= rva < sva + max(vsz, rsz):
            return name, ch
    return None, 0

def is_exec(secs, imgbase, va):
    _, ch = sect_of(secs, imgbase, va)
    return bool(ch & 0x20000000)

def main(path):
    d, imgbase, secs = load(path)
    print(f"== {path}\nimagebase={imgbase:#x}")
    found = []
    for name, sva, vsz, rptr, rsz, ch in secs:
        for off in range(rptr, rptr + rsz - 48, 4):
            if struct.unpack_from("<I", d, off)[0] == 0x300:
                ptrs = [struct.unpack_from("<I", d, off+4+4*k)[0] for k in range(12)]
                if sum(1 for p in ptrs if is_exec(secs, imgbase, p)) >= 9:
                    found.append((imgbase + sva + (off - rptr), ptrs))
    for va, p in found:
        acc, con = p[OFF["ssl_accept"]], p[OFF["ssl_connect"]]
        kind = ("client" if con != acc and is_exec(secs, imgbase, con) and
                "stub" in ("stub" if acc else "") else "")
        # client method: accept is the shared undefined stub, connect is real
        role = "CLIENT" if (con != acc) else "server/both?"
        print(f"\nSSL_METHOD @ {va:#010x}  [{sect_of(secs,imgbase,va)[0]}]  role~{role}")
        for f, k in OFF.items():
            print(f"   +{k*4+4:#04x} {f:12} = {p[k]:#010x}  patch@{va+4+k*4:#010x}")
    print(f"\n({len(found)} table(s); the CLIENT method with a real ssl_connect is the detour target)")

if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else
         "output/_ghidra/securom_dump/mercs2_nodrm_v3.exe")
