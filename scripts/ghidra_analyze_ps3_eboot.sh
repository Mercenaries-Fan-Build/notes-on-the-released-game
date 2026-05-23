#!/usr/bin/env bash
# Headless Ghidra import + analyze for decrypted PS3 EBOOT.elf (PPC64 BE).
#
# Requires: brew install ghidra, JDK 21+ (via asdf — see .tool-versions and docs/ps3_ppc_re_workflow.md)
#
# Usage (from repo root):
#   ./scripts/ghidra_analyze_ps3_eboot.sh
#   ghidraRun   # GUI — run from a shell where `java -version` works (same asdf shims)

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EBOOT="${REPO_ROOT}/analysis/cross_platform/ps3_eboot/EBOOT.elf"
PROJECT_DIR="${REPO_ROOT}/analysis/cross_platform/ghidra_projects"
PROJECT_NAME="Mercenaries2_PS3_EBOOT"

# --- Java (Ghidra 12 needs JDK 17+; 21 recommended) ---
# Prefer asdf (repo .tool-versions or global), then Homebrew openjdk@21.
_resolve_java_home() {
  if [[ -n "${JAVA_HOME:-}" && -x "${JAVA_HOME}/bin/java" ]]; then
    return 0
  fi

  local asdf_sh=""
  for candidate in "${ASDF_DIR:-$HOME/.asdf}/asdf.sh" "$(brew --prefix asdf 2>/dev/null)/libexec/asdf.sh"; do
    if [[ -f "$candidate" ]]; then
      asdf_sh="$candidate"
      break
    fi
  done
  if [[ -n "$asdf_sh" ]]; then
    # shellcheck source=/dev/null
    . "$asdf_sh"
  fi

  if command -v asdf >/dev/null 2>&1; then
    # Pick up java from repo .tool-versions when present
    (cd "$REPO_ROOT" && asdf reshim java 2>/dev/null) || true
    local java_bin
    java_bin="$(cd "$REPO_ROOT" && asdf which java 2>/dev/null || true)"
    if [[ -n "$java_bin" && -x "$java_bin" ]]; then
      JAVA_HOME="$(cd "$(dirname "$java_bin")/.." && pwd)"
      export JAVA_HOME
      return 0
    fi
  fi

  local brew_jdk
  brew_jdk="$(brew --prefix openjdk@21 2>/dev/null || true)"
  if [[ -n "$brew_jdk" ]]; then
    if [[ -d "$brew_jdk/libexec/openjdk.jdk/Contents/Home" ]]; then
      JAVA_HOME="$brew_jdk/libexec/openjdk.jdk/Contents/Home"
    elif [[ -x "$brew_jdk/bin/java" ]]; then
      JAVA_HOME="$brew_jdk"
    fi
    export JAVA_HOME
  fi
}

_resolve_java_home

if [[ -z "${JAVA_HOME:-}" || ! -x "${JAVA_HOME}/bin/java" ]]; then
  echo "error: no JDK found for Ghidra." >&2
  echo "  asdf:  asdf plugin add java https://github.com/halcyon/asdf-java.git" >&2
  echo "         asdf install   # installs java from .tool-versions (temurin-21)" >&2
  echo "  or:    export JAVA_HOME=\$(/usr/libexec/java_home -v 21)  # macOS" >&2
  echo "  or:    brew install openjdk@21" >&2
  exit 1
fi

export PATH="${JAVA_HOME}/bin:${PATH}"
echo "Using JAVA_HOME=$JAVA_HOME"
"${JAVA_HOME}/bin/java" -version 2>&1 | sed 's/^/  /'

if [[ ! -f "$EBOOT" ]]; then
  echo "error: missing $EBOOT — run ./scripts/decrypt_ps3_eboot.sh first" >&2
  exit 1
fi

GHIDRA_HOME="$(brew --prefix ghidra 2>/dev/null)/libexec"
HEADLESS="${GHIDRA_HOME}/support/analyzeHeadless"
if [[ ! -x "$HEADLESS" ]]; then
  echo "error: analyzeHeadless not found at $HEADLESS (brew install ghidra)" >&2
  exit 1
fi

mkdir -p "$PROJECT_DIR"

# Ghidra 12: -analysisTimeoutPerFile 0 means timeout *immediately* (0 seconds), not unlimited.
# Default: import only (-noanalysis); run Auto Analyze in GUI or set GHIDRA_ANALYSIS_TIMEOUT.
ANALYSIS_TIMEOUT="${GHIDRA_ANALYSIS_TIMEOUT:-}"
HEADLESS_ARGS=(
  "$PROJECT_DIR" "$PROJECT_NAME"
  -import "$EBOOT"
  -overwrite
  -processor "PowerPC:BE:64:default"
  -loader ElfLoader
)

if [[ -n "$ANALYSIS_TIMEOUT" ]]; then
  HEADLESS_ARGS+=(-analysisTimeoutPerFile "$ANALYSIS_TIMEOUT")
  echo "  Analysis timeout: ${ANALYSIS_TIMEOUT}s"
else
  HEADLESS_ARGS+=(-noanalysis)
  echo "  Analysis: skipped (-noanalysis). Run Auto Analyze in GUI or:"
  echo "    GHIDRA_ANALYSIS_TIMEOUT=7200 make ghidra-ps3-eboot"
fi

echo ""
echo "Ghidra headless: $PROJECT_NAME"
echo "  ELF:     $EBOOT"
echo "  Project: $PROJECT_DIR"
echo ""

"$HEADLESS" "${HEADLESS_ARGS[@]}"

echo ""
echo "Done. Open GUI: ghidraRun → project $PROJECT_NAME"
if [[ -z "$ANALYSIS_TIMEOUT" ]]; then
  echo "  In GUI: Analysis → Auto Analyze (full run may take 1–2+ hours on 18 MB ELF)"
fi
echo "  String VZ.WAD @ 0x00DDAB78 → References → walk callers for 0x80800 decrypt"
echo "  Quick xrefs: ./scripts/r2_vz_wad_xrefs.sh"
echo "  See docs/ps3_ppc_re_workflow.md"
