#!/usr/bin/env python3
"""Parse Xbox 360 XEX2 headers: report encryption/compression + scan for debug
symbol evidence (PDB path, source-file paths, assert strings)."""
import re, struct, sys
from pathlib import Path

OPT_NAMES = {
    0x000002FF: "ResourceInfo", 0x000003FF: "BaseFileFormat",
    0x00000200: "BaseFileTimeStamp",
    0x00010100: "ImageBaseAddr", 0x00010001: "EntryPoint",
    0x00010201: "PE_ImageBaseAddress",
    0x000103FF: "ImportLibraries",
    0x00018002: "Checksum/Timestamp",
    0x00018102: "Unknown(0x18102)",
    0x000183FF: "OriginalPEName",
    0x000200FF: "StaticLibraries",
    0x00020104: "ExportsByName?",
    0x00020200: "TLSInfo",
    0x00030000: "Unknown(0x30000)",
    0x00040006: "ExecutionId",
    0x00040404: "FileDataDescriptor?",
}


def _ver(v):
    """Decode an XEX version dword: major(4) minor(4) build(16) qfe(8)."""
    return "%d.%d.%d.%d" % ((v >> 28) & 0xF, (v >> 24) & 0xF, (v >> 8) & 0xFFFF, v & 0xFF)


def parse(path: Path):
    d = path.read_bytes()
    magic = d[:4]
    print(f"\n=== {path.name} ({len(d):,} B) magic={magic!r}")
    if magic not in (b"XEX2", b"XEX1", b"XEX%", b"XEX-", b"XEX?"):
        print("  not a XEX"); return d, None
    modflags, pe_off, _res, sec_off, optcount = struct.unpack_from(">IIIII", d, 4)
    print(f"  module_flags=0x{modflags:08x}  pe_data_off=0x{pe_off:x}  "
          f"security_off=0x{sec_off:x}  opt_headers={optcount}")
    flagbits = {0x01:"TITLE",0x02:"EXPORTS_TO_TITLE",0x04:"SYSTEM_DEBUGGER",
                0x08:"DLL_MODULE",0x10:"MODULE_PATCH",0x20:"PATCH_FULL",
                0x40:"PATCH_DELTA",0x80:"USER_MODE"}
    print("  flags:", ", ".join(n for b,n in flagbits.items() if modflags & b) or "-")
    opt = {}
    for i in range(optcount):
        key, val = struct.unpack_from(">II", d, 0x18 + i*8)
        opt[key] = val
    for k, v in opt.items():
        print(f"    opt 0x{k:08x} {OPT_NAMES.get(k,''):16} = 0x{v:x}")

    # BaseFileFormat optional header (0x3FF): describes compression + encryption
    bff = opt.get(0x000003FF)
    if bff:
        # at offset bff: u32 size, u16 encryption_type, u16 compression_type
        enc = struct.unpack_from(">H", d, bff+4)[0]
        comp = struct.unpack_from(">H", d, bff+6)[0]
        print(f"  BaseFileFormat: encryption={enc} ({'NONE' if enc==0 else 'ENCRYPTED'})"
              f"  compression={comp} ({'raw' if comp==1 else 'LZX' if comp==2 else comp})")
        if comp == 2:
            win, first = struct.unpack_from(">II", d, bff+8)
            print(f"    LZX window_size=0x{win:x} first_block_size=0x{first:x}")

    # ExecutionId (0x40006): media/version/base_version/title_id + platform/disc
    ex = opt.get(0x00040006)
    if ex:
        media, ver, bver, title = struct.unpack_from(">IIII", d, ex)
        plat, etab, disc, dcnt = struct.unpack_from(">BBBB", d, ex+16)
        pub = struct.pack(">H", title >> 16).decode("latin1", "replace")
        print(f"  ExecutionId: title_id=0x{title:08x} (pub='{pub}' num=0x{title&0xFFFF:04x})  "
              f"media_id=0x{media:08x}  version={_ver(ver)}  base_version={_ver(bver)}")
        print(f"    platform={plat} exec_table={etab} disc={disc}/{dcnt}")

    # OriginalPEName (0x183ff): length-prefixed ASCII PE name
    pn = opt.get(0x000183FF)
    if pn:
        sz = struct.unpack_from(">I", d, pn)[0]
        s = d[pn+4:pn+4+sz].split(b"\0")[0].decode("latin1", "replace")
        print(f"  OriginalPEName: {s!r}")

    # StaticLibraries (0x200ff): XDK static-lib version stamps
    sl = opt.get(0x000200FF)
    if sl:
        ssize = struct.unpack_from(">I", d, sl)[0]
        n = (ssize - 4) // 0x10
        print(f"  StaticLibraries ({n}):")
        o = sl + 4
        for _ in range(n):
            nm = d[o:o+8].rstrip(b"\0").decode("latin1", "replace")
            mj, mn, bld, qfe = struct.unpack_from(">HHHH", d, o+8)
            print(f"    {nm:<10} {mj}.{mn}.{bld}.{qfe}")
            o += 0x10

    # ImportLibraries (0x103ff): runtime imports (xam/xboxkrnl/xbdm) + XDK version
    il = opt.get(0x000103FF)
    if il:
        size, strtab_size = struct.unpack_from(">II", d, il)
        names = [s.decode("latin1") for s in d[il+12:il+8+strtab_size].split(b"\0") if s]
        print(f"  ImportLibraries: {names}")
        o = il + 8 + strtab_size
        end = il + size
        while o + 0x28 <= end:
            bsize = struct.unpack_from(">I", d, o)[0]
            if not (0x24 <= bsize <= 0x4000) or o + bsize > end:
                o += 4
                continue
            ver, vermin = struct.unpack_from(">II", d, o+0x1c)
            nidx, rec = struct.unpack_from(">HH", d, o+0x24)
            nm = names[nidx] if nidx < len(names) else f"?{nidx}"
            print(f"    {nm:<14} ver={_ver(ver)} ver_min={_ver(vermin)} records={rec}")
            o += bsize

    return d, pe_off


def scan_debug(d: bytes, label: str):
    print(f"\n--- debug-symbol scan: {label} ---")
    pats = {
        ".pdb path": rb"[ -~]{0,80}\.pdb",
        "source .cpp/.h": rb"[A-Za-z]:\\[ -~]{3,90}\.(?:cpp|h|c|inl)\b",
        "win path": rb"[A-Za-z]:\\[ -~]{4,90}",
        "assert": rb"[ -~]{0,40}[Aa]ssert[ -~]{0,60}",
    }
    for name, pat in pats.items():
        hits = sorted(set(m.group() for m in re.finditer(pat, d)))
        print(f"  [{name}] {len(hits)} unique")
        for h in hits[:25]:
            print("     ", h.decode("latin1","replace"))


if __name__ == "__main__":
    for p in sys.argv[1:]:
        d, _ = parse(Path(p))
        scan_debug(d, Path(p).name)
