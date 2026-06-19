#!/usr/bin/env python3
"""foldlog — collapse near-duplicate log lines into readable summaries for an agent.

Each line is reduced to a TEMPLATE by masking volatile tokens (hex, decimals).
Consecutive runs of the same template that are at least --min long are folded
into: the first line verbatim, a fold marker with the count and a compact
summary of what varied, and (optionally) the last line of the run. Lines that
don't form a long enough run are passed through untouched, so ordering and
context are preserved.

Usage:
    python tools/foldlog.py INPUT.log [-o OUTPUT.log] [--min N] [--samples K]

    --min N      minimum run length to fold (default 4)
    --samples K  show up to K distinct example values per varying slot (default 3)
    --keep-last  also print the last line of each folded run (default off)
"""
import argparse
import re
import sys

HEX = re.compile(r"0x[0-9A-Fa-f]+")
NUM = re.compile(r"\d+")
WS = re.compile(r"[ \t]+")


def templatize(line: str):
    """Return (template, captured_tokens). Volatile tokens become placeholders."""
    caps = []

    def grab(m):
        caps.append(m.group(0))
        return "\0H\0" if m.group(0).startswith("0x") else "\0N\0"

    # mask hex first so its digits aren't eaten by the decimal pass
    t = HEX.sub(grab, line)
    t = NUM.sub(grab, t)
    # collapse whitespace runs so column-padding differences (e.g. "[  9]" vs
    # "[ 100]") don't split an otherwise-identical line into separate templates
    t = WS.sub(" ", t).strip()
    return t, caps


def render_template(t: str) -> str:
    return t.replace("\0H\0", "<hex>").replace("\0N\0", "<n>")


def summarize(rows, samples):
    """rows = list of captured-token lists for the folded run. Summarize each slot."""
    if not rows or not rows[0]:
        return ""
    width = len(rows[0])
    parts = []
    for i in range(width):
        vals = [r[i] for r in rows if i < len(r)]
        distinct = list(dict.fromkeys(vals))  # preserve order, dedupe
        if len(distinct) == 1:
            continue  # this slot was constant across the run; not interesting
        shown = ", ".join(distinct[:samples])
        more = f" …+{len(distinct) - samples}" if len(distinct) > samples else ""
        parts.append(f"#{i}={{{shown}{more}}} ({len(distinct)} distinct)")
    return "; ".join(parts)


def fold(infile, outfile, min_run, samples, keep_last):
    lines = infile.read().splitlines()
    out = []
    i = 0
    n = len(lines)
    folded_lines = 0
    while i < n:
        tmpl, caps = templatize(lines[i])
        j = i + 1
        run_caps = [caps]
        while j < n:
            t2, c2 = templatize(lines[j])
            if t2 != tmpl:
                break
            run_caps.append(c2)
            j += 1
        run = j - i
        if run >= min_run:
            out.append(lines[i])
            summ = summarize(run_caps, samples)
            marker = f"  ⤷ ×{run} more lines matching: {render_template(tmpl).strip()}"
            out.append(marker)
            if summ:
                out.append(f"     varied: {summ}")
            if keep_last:
                out.append(f"     last: {lines[j - 1]}")
            folded_lines += run - 1
        else:
            out.extend(lines[i:j])
        i = j

    text = "\n".join(out) + "\n"
    outfile.write(text)
    return n, len(out), folded_lines


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("input")
    ap.add_argument("-o", "--output")
    ap.add_argument("--min", type=int, default=4, dest="min_run")
    ap.add_argument("--samples", type=int, default=3)
    ap.add_argument("--keep-last", action="store_true")
    args = ap.parse_args()

    with open(args.input, "r", encoding="utf-8", errors="replace") as f:
        if args.output:
            with open(args.output, "w", encoding="utf-8") as g:
                src, kept, saved = fold(f, g, args.min_run, args.samples, args.keep_last)
        else:
            import io
            buf = io.StringIO()
            src, kept, saved = fold(f, buf, args.min_run, args.samples, args.keep_last)
            sys.stdout.reconfigure(encoding="utf-8")
            sys.stdout.write(buf.getvalue())

    print(
        f"\n[foldlog] {src} lines -> {kept} lines ({saved} folded, "
        f"{100 * saved // max(src, 1)}% reduction)",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
