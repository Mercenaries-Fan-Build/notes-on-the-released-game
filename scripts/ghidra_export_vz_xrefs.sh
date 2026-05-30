#!/usr/bin/env bash
# Run ExportVzWadXrefs.java on the analyzed Ghidra project (no re-import).
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_DIR="${REPO_ROOT}/analysis/cross_platform/ghidra_projects"
PROJECT_NAME="Mercenaries2_PS3_EBOOT"
OUT="${REPO_ROOT}/analysis/cross_platform/ps3_eboot/ghidra_vz_wad_xrefs.txt"

export GHIDRA_VZ_XREF_OUT="$OUT"

_resolve_java_home() {
  if [[ -n "${JAVA_HOME:-}" && -x "${JAVA_HOME}/bin/java" ]]; then return 0; fi
  for candidate in "${ASDF_DIR:-$HOME/.asdf}/asdf.sh" "$(brew --prefix asdf 2>/dev/null)/libexec/asdf.sh"; do
    [[ -f "$candidate" ]] && . "$candidate" && break
  done
  if command -v asdf >/dev/null 2>&1; then
    local jb; jb="$(cd "$REPO_ROOT" && asdf which java 2>/dev/null || true)"
    [[ -n "$jb" ]] && JAVA_HOME="$(cd "$(dirname "$jb")/.." && pwd)" && export JAVA_HOME
  fi
  local b; b="$(brew --prefix openjdk@21 2>/dev/null || true)"
  if [[ -n "$b" && -d "$b/libexec/openjdk.jdk/Contents/Home" ]]; then
    JAVA_HOME="$b/libexec/openjdk.jdk/Contents/Home"
    export JAVA_HOME
  fi
}
_resolve_java_home
export PATH="${JAVA_HOME}/bin:${PATH}"

GHIDRA_HOME="$(brew --prefix ghidra 2>/dev/null)/libexec"
HEADLESS="${GHIDRA_HOME}/support/analyzeHeadless"
SCRIPT_DIR="${REPO_ROOT}/scripts/ghidra_scripts"

mkdir -p "$(dirname "$OUT")"
echo "Exporting VZ.WAD xrefs → $OUT"

"$HEADLESS" \
  "$PROJECT_DIR" "$PROJECT_NAME" \
  -process "EBOOT.elf" \
  -noanalysis \
  -scriptPath "$SCRIPT_DIR" \
  -postScript ExportVzWadXrefs.java

echo ""
if [[ -f "$OUT" ]]; then
  cat "$OUT"
else
  echo "error: output not created" >&2
  exit 1
fi
