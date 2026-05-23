#!/usr/bin/env bash
# Quick radare2 xref check for VZ.WAD string in decrypted EBOOT.elf.
# Requires: brew install radare2

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EBOOT="${REPO_ROOT}/analysis/cross_platform/ps3_eboot/EBOOT.elf"
VADDR="0xDDAB78"

if [[ ! -f "$EBOOT" ]]; then
  echo "error: missing $EBOOT" >&2
  exit 1
fi

command -v r2 >/dev/null || { echo "error: r2 not found (brew install radare2)" >&2; exit 1; }

R2FLAGS=( -e bin.relocs.apply=true )

echo "=== Strings matching VZ.WAD ==="
r2 -q "${R2FLAGS[@]}" -c "iz~VZ.WAD" -c "q" "$EBOOT"

echo ""
echo "=== Code xrefs to $VADDR ==="
r2 -q "${R2FLAGS[@]}" -c "axt @ $VADDR" -c "q" "$EBOOT"

echo ""
echo "=== Seek string and axt* (alternate) ==="
r2 -q "${R2FLAGS[@]}" -c "s $VADDR; axt" -c "q" "$EBOOT"
