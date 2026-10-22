#!/usr/bin/env bash
# scripts/ghidra_analyze_x360_final.sh
#
# Headless Ghidra decomp of the Xbox 360 devkit Final PE
# (image_id xenon_devkit_final — Jul 11 2008 preview boot exe).
#
# Same pipeline as ghidra_analyze_x360_retail.sh — different input image,
# different output dir. Second-source Final-config name oracle: gives a
# cross-check against the retail Final layout.
#
# Usage (from repo root, in Git Bash):
#   ./scripts/ghidra_analyze_x360_final.sh
#
# Env knobs (all optional):
#   MAXMEM                  Ghidra Java heap (default 8G)
#   GHIDRA_ANALYSIS_TIMEOUT Per-file analysis timeout in seconds (default 21600 = 6h)
#   SKIP_FIX_PE             Skip the PE-fixup step (default: run if output missing/stale)
#
# Required env:
#   GHIDRA_THREADS          ExportFunctions.java decompiler threads (-Dcpu.core.override)
#
# ExportFunctions.java writes the raw-name export, NameFromStrings.java names functions, and
# ExportFunctions.java writes the named export. ExportFunctions stops unless the program's sha256
# is images.tsv's x360-preview-final sha256; its call lists read
# output/_exemap_exports/x360-preview-final.imports.tsv.

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# --- Inputs ---------------------------------------------------------------
IMAGE_PATH="${REPO_ROOT}/output/jul08_prototype/default_xex.pe.bin"
IMAGE_FIXED="${REPO_ROOT}/output/jul08_prototype/default_xex.pe_ghidra.bin"

# --- Outputs --------------------------------------------------------------
OUT_DIR="${REPO_ROOT}/output/_ghidra_x360_final"
PROJECT_DIR="${OUT_DIR}/proj"
PROJECT_NAME="mercs2xenon_final"
IMAGE_ID="x360-preview-final"
DECOMP_RAW="${OUT_DIR}/xenon_final.functions_raw.jsonl"
DECOMP_NAMED="${OUT_DIR}/xenon_final.functions.jsonl"
IMPORTS="${REPO_ROOT}/output/_exemap_exports/${IMAGE_ID}.imports.tsv"
ORDINALS="${REPO_ROOT}/scripts/ghidra_scripts/pe_import_ordinals.tsv"
RUN_LOG="${OUT_DIR}/run.log"

# --- Toolchain (bundled) --------------------------------------------------
export JAVA_HOME="${REPO_ROOT}/tools/jdk21/jdk-21.0.11+10"
GHIDRA_HOME="${REPO_ROOT}/tools/ghidra_12.1_PUBLIC"
HEADLESS="${GHIDRA_HOME}/support/analyzeHeadless.bat"
SCRIPT_PATH="${REPO_ROOT}/tools/ghidra_x360"
EXPORT_SCRIPT_PATH="${REPO_ROOT}/scripts/ghidra_scripts"

# --- Runtime knobs --------------------------------------------------------
export MAXMEM="${MAXMEM:-8G}"
ANALYSIS_TIMEOUT="${GHIDRA_ANALYSIS_TIMEOUT:-21600}"
SKIP_FIX_PE="${SKIP_FIX_PE:-0}"
# Opt-in verbose logging. Set GHIDRA_LOG_CONFIG=<path/to/log4j2.xml> to promote
# selected Ghidra loggers to DEBUG. See tools/ghidra_x360/log4j2-verbose.xml.
GHIDRA_LOG_CONFIG="${GHIDRA_LOG_CONFIG:-}"

# --- Preflight ------------------------------------------------------------
_die() { echo "error: $*" >&2; exit 1; }
[[ -f "$IMAGE_PATH" ]] || _die "missing image at $IMAGE_PATH — see exe_images.md xenon_devkit_final"
[[ -x "${JAVA_HOME}/bin/java.exe" || -x "${JAVA_HOME}/bin/java" ]] \
  || _die "bundled JDK not found at $JAVA_HOME"
[[ -f "$HEADLESS" ]]  || _die "analyzeHeadless.bat not found at $HEADLESS"
[[ -f "${REPO_ROOT}/tools/fix_xbox_pe_for_ghidra.py" ]] \
  || _die "fix_xbox_pe_for_ghidra.py not found in tools/"
for js in CreateFunctions.java NameFromStrings.java; do
  [[ -f "${SCRIPT_PATH}/${js}" ]] || _die "Ghidra script missing: ${SCRIPT_PATH}/${js}"
done
[[ -f "${EXPORT_SCRIPT_PATH}/ExportFunctions.java" ]] \
  || _die "Ghidra script missing: ${EXPORT_SCRIPT_PATH}/ExportFunctions.java"
[[ -f "$IMPORTS" ]] || _die "missing imports sidecar $IMPORTS (exemap imports)"
[[ "${GHIDRA_THREADS:-}" =~ ^[1-9][0-9]*$ ]] \
  || _die "GHIDRA_THREADS (ExportFunctions decompiler threads) is '${GHIDRA_THREADS:-}'"
# shellcheck source=scripts/ghidra_tables.sh
source "${REPO_ROOT}/scripts/ghidra_tables.sh"
IMAGE_SHA=$(image_export_sha256 "$IMAGE_ID") || _die "no images.tsv sha256 for $IMAGE_ID"
export GHIDRA_HEADLESS_JAVA_OPTIONS="${GHIDRA_HEADLESS_JAVA_OPTIONS:-} -Dcpu.core.override=${GHIDRA_THREADS}"
for f in "$DECOMP_RAW" "$DECOMP_NAMED"; do
  if [[ -e "$f" ]]; then echo "removing the previous $f"; rm "$f"; fi
done
if [[ -n "$GHIDRA_LOG_CONFIG" ]]; then
  [[ -f "$GHIDRA_LOG_CONFIG" ]] || _die "GHIDRA_LOG_CONFIG points at missing file: $GHIDRA_LOG_CONFIG"
  export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:-} -Dlog4j.configurationFile=${GHIDRA_LOG_CONFIG}"
fi

mkdir -p "$OUT_DIR" "$PROJECT_DIR"
cat <<EOF
================================================================
 Ghidra headless — Xbox 360 devkit Final (image_id: xenon_devkit_final)
================================================================
  Input PE:        $IMAGE_PATH
  Fixed PE:        $IMAGE_FIXED
  Project dir:     $PROJECT_DIR
  Project name:    $PROJECT_NAME
  Decomp (raw):    $DECOMP_RAW
  Decomp (named):  $DECOMP_NAMED
  Run log:         $RUN_LOG

  JAVA_HOME:       $JAVA_HOME
  MAXMEM:          $MAXMEM
  Analysis timeout: ${ANALYSIS_TIMEOUT}s
  Log config:      ${GHIDRA_LOG_CONFIG:-(default — INFO)}
  Processor:       PowerPC:BE:64:A2ALT-32addr
  Image base:      0x82000000
================================================================
EOF

# --- Step 1: PE fixup ----------------------------------------------------
if [[ "$SKIP_FIX_PE" == "1" ]]; then
  echo "[1/2] SKIP_FIX_PE=1 — assuming $IMAGE_FIXED is current"
  [[ -f "$IMAGE_FIXED" ]] || _die "SKIP_FIX_PE set but $IMAGE_FIXED does not exist"
elif [[ ! -f "$IMAGE_FIXED" ]] || [[ "$IMAGE_PATH" -nt "$IMAGE_FIXED" ]]; then
  echo "[1/2] Fixing PE for Ghidra loader..."
  python "${REPO_ROOT}/tools/fix_xbox_pe_for_ghidra.py" "$IMAGE_PATH" "$IMAGE_FIXED"
  echo "     -> $IMAGE_FIXED"
else
  echo "[1/2] Fixed PE up-to-date — skipping fix pass."
fi

# --- Step 2: Ghidra ------------------------------------------------------
echo "[2/2] Ghidra headless run..."
echo ""

"$HEADLESS" \
  "$PROJECT_DIR" "$PROJECT_NAME" \
  -import "$IMAGE_FIXED" \
  -overwrite \
  -processor "PowerPC:BE:64:A2ALT-32addr" \
  -loader PeLoader \
  -analysisTimeoutPerFile "$ANALYSIS_TIMEOUT" \
  -scriptPath "$SCRIPT_PATH;$EXPORT_SCRIPT_PATH" \
  -preScript CreateFunctions.java \
  -postScript ExportFunctions.java "$IMAGE_ID" "$IMAGE_SHA" "$DECOMP_RAW" "$ORDINALS" "$IMPORTS" \
  -postScript NameFromStrings.java \
  -postScript ExportFunctions.java "$IMAGE_ID" "$IMAGE_SHA" "$DECOMP_NAMED" "$ORDINALS" "$IMPORTS" \
  < /dev/null 2>&1 | tee "$RUN_LOG"
if grep -q "REPORT SCRIPT ERROR" "$RUN_LOG"; then _die "a Ghidra script stopped; see $RUN_LOG"; fi
for f in "$DECOMP_RAW" "$DECOMP_NAMED"; do
  [[ -f "$f" ]] || _die "$f was not written; see $RUN_LOG"
done

echo ""
echo "================================================================"
echo " Done. Summary:"
echo "   Project:        $PROJECT_DIR/$PROJECT_NAME.rep"
echo "   Decomp (raw):   $DECOMP_RAW"
echo "   Decomp (named): $DECOMP_NAMED"
echo "   Run log:        $RUN_LOG"
echo "================================================================"
