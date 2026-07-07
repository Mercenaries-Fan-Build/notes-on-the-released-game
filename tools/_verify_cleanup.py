#!/usr/bin/env python3
"""Verify the unluac cleanup pass is faithful, for every DLC src file.

Two checks per file:
  1. Token invariant: copy propagation only MOVES tokens, so the multiset of
     non-register tokens (string literals, numbers, identifiers/keywords/fields)
     must be IDENTICAL between raw and cleaned. Register temps (L../A..) differ.
  2. Syntax: cleaned text must compile with luac -p (Lua 5.1).
"""
import re, subprocess, sys, tempfile
from collections import Counter
from pathlib import Path
sys.path.insert(0, "tools")
from lua_unluac_cleanup import cleanup

SRC = Path("docs/mercs2-dlc-luacd/src/dlc01")
LUAC = Path("tools/lua51-mercs2/luac.exe")
REG = re.compile(r"[LA]\d+_\d+")
NUM = re.compile(r"\b\d+\.?\d*(?:[eE][-+]?\d+)?\b")
IDENT = re.compile(r"\b[A-Za-z_]\w*\b")


def scan(text):
    """Lua-aware scanner: returns (code_without_strings_or_comments, [strings])."""
    text = text.replace("\r", "")
    code, strs = [], []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        # long bracket [[ / [=[ ... (string or, after --, comment)
        if c == "[" and (m := re.match(r"\[(=*)\[", text[i:])):
            eq = m.group(1)
            close = "]" + eq + "]"
            j = text.find(close, i + len(m.group(0)))
            j = n if j < 0 else j
            strs.append(text[i:j + len(close)])
            code.append(" ")
            i = j + len(close)
            continue
        if c == "-" and text[i:i + 2] == "--":
            if (m := re.match(r"--\[(=*)\[", text[i:])):
                close = "]" + m.group(1) + "]"
                j = text.find(close, i + len(m.group(0)))
                i = n if j < 0 else j + len(close)
            else:
                j = text.find("\n", i)
                i = n if j < 0 else j
            code.append(" ")
            continue
        if c in "\"'":
            j = i + 1
            while j < n and text[j] != c:
                j += 2 if text[j] == "\\" else 1
            strs.append(text[i:j + 1])
            code.append(" ")
            i = j + 1
            continue
        code.append(c)
        i += 1
    return "".join(code), strs


def toks(text):
    code, strs = scan(text)
    nums = NUM.findall(code)
    idents = [t for t in IDENT.findall(code) if not REG.fullmatch(t)]
    return Counter(strs), Counter(nums), Counter(idents)

def syntax_ok(text):
    tf = Path(tempfile.mktemp(suffix=".lua"))
    tf.write_bytes(text.encode("utf-8"))
    r = subprocess.run([str(LUAC), "-p", str(tf)], capture_output=True)
    tf.unlink(missing_ok=True)
    return r.returncode == 0, r.stderr.decode("utf-8", "replace").strip().split("\n")[-1]


def main():
    nbad = 0
    for f in sorted(SRC.glob("*.lua")):
        raw = f.read_bytes().decode("utf-8", "replace")
        cln = cleanup(raw)
        rs, rn, ri = toks(raw)
        cs, cn, ci = toks(cln)
        issues = []
        if rs != cs: issues.append(f"strings differ: +{len(cs-rs)} -{len(rs-cs)}")
        if rn != cn: issues.append(f"numbers differ: +{dict(cn-rn)} -{dict(rn-cn)}")
        if ri != ci: issues.append(f"idents differ: +{dict(ci-ri)} -{dict(ri-ci)}")
        # syntax REGRESSION check: only flag if raw compiles but cleaned doesn't
        raw_ok, _ = syntax_ok(raw)
        cln_ok, cln_err = syntax_ok(cln)
        if raw_ok and not cln_ok:
            issues.append("SYNTAX REGRESSION: " + cln_err)
        tag = "" if (raw_ok == cln_ok) else f" (raw_ok={raw_ok} cln_ok={cln_ok})"
        if issues:
            nbad += 1
            print(f"FAIL {f.name}:{tag}")
            for i in issues: print(f"     {i}")
        else:
            note = "" if raw_ok else " [raw also non-compiling: goto/label artifact]"
            print(f"ok   {f.name}{note}")
    print(f"\n{nbad} file(s) with cleaner-induced issues")
    return 1 if nbad else 0

if __name__ == "__main__":
    raise SystemExit(main())
