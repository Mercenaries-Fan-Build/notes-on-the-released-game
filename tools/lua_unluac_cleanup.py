#!/usr/bin/env python3
"""Readability post-pass for unluac output of *debug-stripped* Lua 5.1 bytecode.

unluac, with no debug info, materialises every VM register as a named local
(``L0_1``) and emits one statement per assignment, so a single source line such
as ``import("MrxSupport", false)`` becomes::

    L0_1 = import
    L1_1 = "MrxSupport"
    L2_1 = false
    L0_1(L1_1, L2_1)

This module performs conservative **copy propagation** to fold those temporaries
back into expressions, then drops the now-unused entries from the leading
``local ...`` declaration.  It is purely cosmetic and is designed to never change
semantics:

Folding ``reg = rhs`` (at line i) into its single use (at line j) is performed
only when ALL hold:
  * ``reg`` is a compiler temporary (``L<n>_<n>`` / ``A<n>_<n>``);
  * ``reg`` is read exactly once between i and its next redefinition, at line j;
  * no register read by ``rhs`` is reassigned in the open interval (i, j);
  * no global identifier read by ``rhs`` is assigned by a statement in (i, j);
  * either j == i+1 (adjacent — no statements reordered) OR ``rhs`` is
    side-effect-free by syntax (literal / name / dotted-name / register; never a
    call ``f(...)`` or index ``t[...]``).
Folding never crosses a control-flow boundary (if/while/for/function/return/
break/do/end/else/elseif/repeat/until/goto/label) — those act as barriers.

The verbatim unluac output is always kept elsewhere as the authoritative source;
treat this output as a reading aid and verify against the raw form before acting.
"""
from __future__ import annotations

import re

REG_RE = re.compile(r"\b[LA]\d+_\d+\b")
# A line begins a new control structure / barrier if it contains these as words.
BARRIER_RE = re.compile(
    r"(^|\s)(if|while|for|function|return|break|do|end|else|elseif|repeat|until|goto|then)(\s|$|\()"
    r"|::"
)
# Comparison / relational operators whose '=' must not be read as assignment.
_NOT_ASSIGN = ("==", "~=", "<=", ">=")
IDENT_RE = re.compile(r"\b[A-Za-z_]\w*\b")
# rhs is "pure" (no call / no index) if it is only names, dotted names, regs,
# literals, and basic operators — i.e. contains no '(' and no '['.
PURE_RHS_RE = re.compile(r"^[^\(\[]*$")


def _split_assign(line: str):
    """Return (indent, lhs, rhs) for a top-level ``lhs = rhs`` statement, else None."""
    s = line.rstrip("\n")
    # find the first '=' that is not part of ==, ~=, <=, >=
    i = 0
    while i < len(s):
        c = s[i]
        if c == "=":
            prev = s[i - 1] if i else ""
            nxt = s[i + 1] if i + 1 < len(s) else ""
            if prev in "=~<>" or nxt == "=":
                i += 1
                continue
            lhs = s[:i].rstrip()
            rhs = s[i + 1:].strip()
            indent = line[: len(line) - len(line.lstrip())]
            return indent, lhs, rhs
        # skip string literals so '=' inside strings is ignored
        if c in "\"'":
            q = c
            i += 1
            while i < len(s) and s[i] != q:
                if s[i] == "\\":
                    i += 1
                i += 1
        i += 1
    return None


def _lhs_root(lhs: str) -> str | None:
    """The identifier/register being written, for clobber tracking. ``L0_1`` for
    ``L0_1``; ``Pg`` for ``Pg.x`` / ``Pg[1]``; None for multi-target."""
    lhs = lhs.strip()
    if "," in lhs:
        return None
    m = re.match(r"\s*([A-Za-z_]\w*)", lhs)
    return m.group(1) if m else None


def _is_temp(tok: str) -> bool:
    return bool(re.fullmatch(r"[LA]\d+_\d+", tok))


def _needs_paren(rhs: str) -> bool:
    """True if rhs has a top-level binary/unary operator (so inlining it into a
    larger expression could change precedence). Atoms — names, dotted names,
    indexes ``t[k]``, calls ``f(x)``, literals, table ctors — return False.
    Over-paren is always safe; this only avoids ugly parens around atoms."""
    s = rhs.strip()
    if re.fullmatch(r"(true|false|nil)", s):
        return False
    depth = 0
    i = 0
    ops = ("..", "==", "~=", "<=", ">=", "+", "-", "*", "/", "%", "^",
           "<", ">", " and ", " or ", " not ")
    while i < len(s):
        c = s[i]
        if c in "([{":
            depth += 1; i += 1; continue
        if c in ")]}":
            depth -= 1; i += 1; continue
        if c in "\"'":
            q = c; i += 1
            while i < len(s) and s[i] != q:
                i += 2 if s[i] == "\\" else 1
            i += 1; continue
        if depth == 0:
            for op in ops:
                if s.startswith(op, i) and i > 0:  # i>0: not a leading unary atom
                    return True
        i += 1
    return False


def _substitute_use(use_text: str, reg: str, sub: str) -> str:
    """Replace the single READ occurrence of ``reg`` with ``sub`` in a use line,
    never touching a write-target occurrence (``reg = ...`` lhs)."""
    parsed = _split_assign(use_text)
    pat = rf"\b{re.escape(reg)}\b"
    if parsed:
        _indent, lhs, rhs = parsed  # lhs already carries the line's indentation
        new_rhs, n = re.subn(pat, lambda _m: sub, rhs, count=1)
        if n:
            return f"{lhs} = {new_rhs}"
        # reg not read in rhs -> it is read in the lhs as an index/field base
        # (e.g. ``reg[k] = x``); a bare ``reg = ...`` write-target was excluded
        # by the caller, so substituting in lhs here is a genuine read.
        new_lhs = re.sub(pat, lambda _m: sub, lhs, count=1)
        return f"{new_lhs} = {rhs}"
    return re.sub(pat, lambda _m: sub, use_text, count=1)


def _clean_block(lines: list[str]) -> list[str]:
    """Copy-propagate within one barrier-free linear run of statements."""
    changed = True
    while changed:
        changed = False
        n = len(lines)
        for i in range(n):
            parsed = _split_assign(lines[i])
            if not parsed:
                continue
            indent, lhs, rhs = parsed
            if not _is_temp(lhs.strip()):
                continue
            reg = lhs.strip()
            rhs_regs = set(REG_RE.findall(rhs))
            rhs_idents = set(IDENT_RE.findall(rhs)) - rhs_regs
            pure = bool(PURE_RHS_RE.match(rhs))
            # scan forward for uses / redefinition / clobbers
            use_line = -1
            uses = 0
            ok = True
            for j in range(i + 1, n):
                ln = lines[j]
                # redefinition of reg ends its live range
                pj = _split_assign(ln)
                # count uses of reg on this line (exclude pure redefinition lhs)
                toks = REG_RE.findall(ln)
                cnt = toks.count(reg)
                is_redef = pj and pj[1].strip() == reg
                if is_redef:
                    # the rhs of the redef may still use reg (reg = reg.x)
                    rhs_cnt = REG_RE.findall(pj[2]).count(reg)
                    if rhs_cnt:
                        uses += rhs_cnt
                        use_line = j
                    break
                if cnt:
                    uses += cnt
                    use_line = j
                # clobber check for the interval (i, j) BEFORE the use
                if uses == 0:
                    if pj:
                        root = _lhs_root(pj[1])
                        if root in rhs_regs or root in rhs_idents:
                            ok = False
                            break
            if uses != 1 or use_line < 0 or not ok:
                continue
            # never inline into a write-target base: ``reg.x = ..`` / ``reg[k] = ..``
            # is an in-place mutation of a live object, not a value read.
            up = _split_assign(lines[use_line])
            if up and re.match(rf"{re.escape(reg)}\s*[.\[]", up[1].strip()):
                continue
            # adjacency or purity gate
            adjacent = (use_line == i + 1)
            if not adjacent and not pure:
                continue
            # if not adjacent, recheck no clobber strictly between i and use_line
            if not adjacent:
                bad = False
                for j in range(i + 1, use_line):
                    pj = _split_assign(lines[j])
                    if pj:
                        root = _lhs_root(pj[1])
                        if root in rhs_regs or root in rhs_idents:
                            bad = True
                            break
                if bad:
                    continue
            # perform substitution on the use line's READ occurrence, wrapping
            # the inlined rhs only when precedence requires it
            use_text = lines[use_line]
            sub = f"({rhs})" if _needs_paren(rhs) else rhs
            lines[use_line] = _substitute_use(use_text, reg, sub)
            del lines[i]
            changed = True
            break
    return lines


def cleanup(text: str) -> str:
    text = text.replace("\r", "")
    raw = text.split("\n")
    out: list[str] = []
    block: list[str] = []

    def flush():
        if block:
            out.extend(_clean_block(block))
            block.clear()

    for line in raw:
        if BARRIER_RE.search(line) or line.strip() == "" or line.lstrip().startswith("local "):
            flush()
            out.append(line)
        else:
            block.append(line)
    flush()

    # drop unused names from leading `local L..,L..` declarations
    body = "\n".join(out)
    live = set(REG_RE.findall(body))

    def prune_decl(m: re.Match) -> str:
        indent, names = m.group(1), m.group(2)
        kept = [x.strip() for x in names.split(",") if x.strip() in live]
        if not kept:
            return ""  # entire declaration now dead
        return f"{indent}local {', '.join(kept)}"

    pruned = []
    for line in out:
        m = re.match(r"(\s*)local\s+([LA][\w,\s]+)$", line)
        if m and all(_is_temp(x.strip()) for x in m.group(2).split(",") if x.strip()):
            # recompute liveness excluding this declaration line itself
            decl_regs = {x.strip() for x in m.group(2).split(",")}
            uses_elsewhere = set(REG_RE.findall("\n".join(
                l for l in out if l is not line))) if False else live
            repl = prune_decl(m)
            if repl == "":
                continue
            pruned.append(repl)
        else:
            pruned.append(line)
    return "\n".join(pruned)


if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        src = sys.stdin.buffer.read().decode("utf-8", "replace")
    else:
        src = open(sys.argv[1], "rb").read().decode("utf-8", "replace")
    sys.stdout.write(cleanup(src))
