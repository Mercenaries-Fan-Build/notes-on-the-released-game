#!/usr/bin/env python3
"""Decompile the Lua scripts shipped in the Mercenaries 2 X360 DLC.

Pipeline:
  1. Extract the STFS DOH WAD (``DLC01.doh``) from the X360 DLC RAR (cached).
  2. Walk every block, decompress the big-endian (Xbox) ``sges`` blocks, and
     locate each ``\\x1bLuaQ`` chunk (the DLC ships them in block 464
     ``blocks\\dlc01\\resident_P000_Q3.block``).
  3. The Xbox Lua header is big-endian / 4-byte float Lua 5.1
     (``1b4c75615100000404040400``).  unluac reads the endianness flag directly,
     so the raw chunk decompiles with no byte-swap.
  4. Recover each script name from the preceding ``BINN`` (Xbox tag ``NNIB``)
     section and write the decompiled source to
     ``docs/mercs2-dlc-luacd/src/dlc01/<name>.lua``.

Usage:
  python tools/decompile_dlc_lua.py
"""
from __future__ import annotations

import mmap
import re
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

ROOT = Path(__file__).resolve().parent.parent
RAR = ROOT / "game-files" / "Mercenaries.2.World.In.Flames.DLC.RF.X360-ZTM.rar"
# An EARLIER, unstripped DLC test build (debug info intact -> clean decompile).
PROTO_ZIP = ROOT / "game-files" / "Mercenaries 2 World in Flames (DLC Blow It Up Again Pack B prototype).zip"
DOH_CACHE = ROOT / "output" / "_scratch" / "dlc_doh" / "dlc.doh"
DOC = ROOT / "docs" / "mercs2-dlc-luacd"
OUT_SRC = DOC / "src" / "dlc01"              # readable (copy-propagated)
RAW_SRC = DOC / "raw" / "dlc01"              # verbatim unluac (authoritative)
PROTO_SRC = DOC / "src" / "dlctest01"        # unstripped prototype (already clean)
JAVA = ROOT / "tools" / "jdk21" / "jdk-21.0.11+10" / "bin" / "java.exe"
UNLUAC = ROOT / "tools" / "external" / "unluac" / "unluac.jar"

from lua_unluac_cleanup import cleanup

LUAQ_SIG = b"\x1bLua"
PAGE_SIZE = 0x8000  # FFCS page size (matches x360_dlc_io.PAGE_SIZE)
BINN_TAG_BE = b"NNIB"  # "BINN" reversed (Xbox big-endian FFCS sub-tag)
# Reversed (Xbox big-endian) FFCS sub-tags that wrap each UCFX script entry.
TAG_WORDS = {"UCFX", "XFCU", "INFO", "OFNI", "DEPS", "SPED", "BINN", "NNIB",
             "CSUM", "MUSC", "ASET", "TESA", "atad"}
NAME_RE = re.compile(rb"[A-Za-z0-9_]{4,}")


def ensure_doh() -> Path:
    if DOH_CACHE.exists() and DOH_CACHE.stat().st_size > 0:
        return DOH_CACHE
    from x360_dlc_io import extract_stfs_from_rar
    DOH_CACHE.parent.mkdir(parents=True, exist_ok=True)
    print(f"Extracting STFS from {RAR.name} ...", flush=True)
    reader = extract_stfs_from_rar(RAR, DOH_CACHE.parent)
    doh = next((e for e in reader.file_table if "doh" in e["name"].lower()), None)
    if doh is None:
        doh = max(reader.file_table, key=lambda e: e["file_size"])
    size = doh["file_size"]
    CH = 64 * 1024 * 1024
    with open(DOH_CACHE, "wb") as f:
        for off in range(0, size, CH):
            f.write(reader.read(off, min(CH, size - off)))
    print(f"DOH '{doh['name']}' -> {DOH_CACHE} ({size:,} B)", flush=True)
    return DOH_CACHE


def script_name(blk: bytes, luaq_off: int) -> str:
    """Recover the asset name from the BINN section preceding a LuaQ chunk.

    Each script entry's name is the length-prefixed string immediately after the
    block's ``BINN`` tag (stored reversed as ``NNIB`` in the big-endian Xbox
    WAD).  Take the FIRST printable run after that tag — the bytes before LuaQ
    are binary INFO/DEPS payload whose incidental ASCII would mislead a
    "last run" heuristic.
    """
    region = blk[max(0, luaq_off - 320):luaq_off]
    nidx = region.rfind(BINN_TAG_BE)
    search = region[nidx + 4:] if nidx >= 0 else region
    for m in NAME_RE.finditer(search):
        w = m.group().decode("latin1")
        if w not in TAG_WORDS:
            return w
    return f"unknown_{luaq_off:08x}"


def iter_lua_chunks(blk: bytes):
    """Yield (name, raw_bytes) for each LuaQ chunk; bound = next LuaQ / end."""
    offs = []
    pos = 0
    while True:
        i = blk.find(LUAQ_SIG, pos)
        if i < 0:
            break
        offs.append(i)
        pos = i + 1
    for idx, o in enumerate(offs):
        end = offs[idx + 1] if idx + 1 < len(offs) else len(blk)
        yield script_name(blk, o), blk[o:end]


def decompile(raw: Path) -> tuple[bool, str]:
    try:
        r = subprocess.run([str(JAVA), "-jar", str(UNLUAC), str(raw)],
                           capture_output=True, timeout=120)
    except subprocess.TimeoutExpired:
        return False, "// unluac timeout\n"
    out = r.stdout.decode("utf-8", "replace")
    err = r.stderr.decode("utf-8", "replace")
    # unluac prints source to stdout; non-empty + no fatal stack trace = success
    if out.strip() and "Exception" not in err and r.returncode == 0:
        return True, out
    return False, err or out


def _write_lua(path: Path, text: str) -> None:
    """Write with normalised LF line endings (unluac emits CRLF on Windows)."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "wb") as f:
        f.write(text.replace("\r\n", "\n").replace("\r", "\n").encode("utf-8"))


def decompile_blocks(ents, paths, mm, decompress, out_src: Path,
                     raw_src: Path | None, clean: bool, label: str) -> tuple[list, list]:
    from_page = decompress
    out_src.mkdir(parents=True, exist_ok=True)
    if raw_src:
        raw_src.mkdir(parents=True, exist_ok=True)
    tmpdir = Path(tempfile.mkdtemp(prefix="dlc_lua_"))
    ok, fail = [], []
    seen: dict[str, int] = {}
    for i, e in enumerate(ents):
        try:
            blk = from_page(mm, e.file_offset, e.page_count * PAGE_SIZE)
        except Exception:
            continue
        if not blk or LUAQ_SIG not in blk:
            continue
        path = paths[i] if i < len(paths) else f"block_{i:05d}"
        print(f"\n[{label} {i}] {path}: {blk.count(LUAQ_SIG)} LuaQ chunks", flush=True)
        for name, raw in iter_lua_chunks(blk):
            if name in seen:
                seen[name] += 1
                name = f"{name}__{seen[name]}"
            else:
                seen[name] = 0
            rawf = tmpdir / f"{name}.luac"
            rawf.write_bytes(raw)
            success, text = decompile(rawf)
            if not success:
                why = text.strip().splitlines()[-1] if text.strip() else "empty"
                fail.append((name, why))
                print(f"    FAIL {name}: {why}")
                continue
            if raw_src:
                _write_lua(raw_src / f"{name}.lua", text)
            _write_lua(out_src / f"{name}.lua", cleanup(text) if clean else text)
            ok.append(name)
            print(f"    OK  {name}.lua ({len(text):,} chars)")
    return ok, fail


def run_retail() -> tuple[list, list]:
    """Retail DLC (X360 rar): big-endian, debug-STRIPPED -> raw + cleaned."""
    doh = ensure_doh()
    from x360_dlc_io import parse_be_ffcs, parse_be_indx, parse_be_pths, PAGE_SIZE
    from wad_be_le_oracle import _decompress_be_block
    fh = open(doh, "rb")
    mm = mmap.mmap(fh.fileno(), 0, access=mmap.ACCESS_READ)
    _v, rows = parse_be_ffcs(mm)
    indx = next(r for r in rows if r.tag == "INDX")
    pths = next((r for r in rows if r.tag == "PTHS"), None)
    ents = parse_be_indx(mm, indx.offset, indx.meta)
    paths = parse_be_pths(mm, pths.offset, pths.meta) if pths else []
    res = decompile_blocks(ents, paths, mm, _decompress_be_block,
                           OUT_SRC, RAW_SRC, clean=True, label="retail")
    mm.close(); fh.close()
    return res


def run_prototype() -> tuple[list, list]:
    """Unstripped DLC prototype (zip->STFS): debug info intact -> clean already."""
    if not PROTO_ZIP.exists():
        print(f"\n(prototype zip not found, skipping: {PROTO_ZIP.name})")
        return [], []
    import zipfile
    from x360_dlc_io import StfsReader, parse_be_ffcs, parse_be_indx, parse_be_pths, PAGE_SIZE
    from wad_be_le_oracle import _decompress_be_block
    zf = zipfile.ZipFile(PROTO_ZIP)
    info = max(zf.infolist(), key=lambda x: x.file_size)
    rdr = StfsReader(zf.read(info))
    doh = next((x for x in rdr.file_table if "doh" in x["name"].lower()), None) \
        or max(rdr.file_table, key=lambda x: x["file_size"])
    data = rdr.read_file(doh)
    _v, rows = parse_be_ffcs(data)
    indx = next(r for r in rows if r.tag == "INDX")
    pths = next((r for r in rows if r.tag == "PTHS"), None)
    ents = parse_be_indx(data, indx.offset, indx.meta)
    paths = parse_be_pths(data, pths.offset, pths.meta) if pths else []
    # debug info present -> unluac yields real names; cleanup is a harmless no-op
    return decompile_blocks(ents, paths, data, _decompress_be_block,
                            PROTO_SRC, None, clean=False, label="proto")


def main() -> int:
    ok_r, fail_r = run_retail()
    ok_p, fail_p = run_prototype()
    print(f"\n=== retail dlc01: {len(ok_r)}/{len(ok_r)+len(fail_r)}  "
          f"(raw -> {RAW_SRC.relative_to(ROOT)}, cleaned -> {OUT_SRC.relative_to(ROOT)})")
    print(f"=== prototype dlctest01: {len(ok_p)}/{len(ok_p)+len(fail_p)}  "
          f"-> {PROTO_SRC.relative_to(ROOT)}")
    fails = [("dlc01", n, w) for n, w in fail_r] + [("dlctest01", n, w) for n, w in fail_p]
    if fails:
        failf = DOC / "_decompile_failures.txt"
        failf.write_text("\n".join(f"{g}/{n}\t{w}" for g, n, w in fails), encoding="utf-8")
        print(f"Failures ({len(fails)}) -> {failf.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
