#!/usr/bin/env bash
# Compile the Xenon SLEIGH spec with the sleigh of the Ghidra install named by the `ghidra_headless`
# key of tools/wad_simulator/.mercs2-local.toml (scripts/ghidra_tables.sh), and package the
# extension zip.
# Usage: build.sh <outZip>
set -euo pipefail
[ $# -eq 1 ] || { echo "usage: build.sh <outZip>" >&2; exit 2; }
OUTZIP="$1"
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
# shellcheck source=scripts/ghidra_tables.sh
source "$REPO_ROOT/scripts/ghidra_tables.sh"
HEADLESS=$(ghidra_headless_path) || exit 2
SLEIGH="$(dirname "$HEADLESS")/sleigh"
[ -x "$SLEIGH" ] || { echo "no sleigh next to $HEADLESS" >&2; exit 2; }

LANGDIR="$HERE/GhidraXenon/data/languages"
rm -f "$LANGDIR/ppc_64_xenon.sla"
"$SLEIGH" "$LANGDIR/ppc_64_xenon.slaspec" "$LANGDIR/ppc_64_xenon.sla"
[ -s "$LANGDIR/ppc_64_xenon.sla" ] || { echo "sleigh produced no .sla" >&2; exit 1; }

rm -f "$OUTZIP"
(cd "$HERE" && zip -r -X "$OUTZIP" GhidraXenon)
echo "built $OUTZIP"
