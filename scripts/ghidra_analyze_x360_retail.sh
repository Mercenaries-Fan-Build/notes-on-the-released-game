#!/usr/bin/env bash
# scripts/ghidra_analyze_x360_retail.sh
#
# Headless Ghidra decomp of the Xbox 360 retail default.xex unpacked PE
# (image_id xenon_retail_jtag_pe from docs/data/exe_images.json).
#
# Windows-first: uses the BUNDLED JDK + Ghidra in-repo per CLAUDE.md's
# portable-toolchain rule. Parallels scripts/ghidra_analyze_ps3_eboot.sh
# in shape, but reworks the JDK/Ghidra resolve for Windows/Git Bash.
#
# Usage (from repo root, in Git Bash):
#   ./scripts/ghidra_analyze_x360_retail.sh
#
# Env knobs (all optional):
#   MAXMEM                  Ghidra Java heap (default 8G — see support/launch.properties)
#   GHIDRA_ANALYSIS_TIMEOUT Per-file analysis timeout in seconds (default 14400 = 4h)
#   SKIP_FIX_PE             Skip the PE-fixup step (default: run if fixed image missing/stale)
#
# Pipeline (per docs/reverse_engineer/xbox_ppc_decompilation.md):
#   1. tools/fix_xbox_pe_for_ghidra.py rewrites PointerToRawData=VirtualAddress
#   2. analyzeHeadless imports PE at 0x82000000, PowerPC:BE:64:A2ALT-32addr
#   3. -preScript CreateFunctions.java seeds from .pdata (38k+ entry points)
#   4. Auto-analyze runs (long — hours)
#   5. -postScript DecompileExport.java writes decomp.c (raw FUN names)
#   6. -postScript NameFromStrings.java applies string-anchored names
#   7. -postScript DecompileExport.java writes decomp_named.c
#
# NOT run in this pipeline (follow-up work):
#   - RttiNameCtors.java   needs per-image rtti_vtables.txt (Phase 2 follow-up)

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# --- Inputs ---------------------------------------------------------------
IMAGE_PATH="${REPO_ROOT}/output/_scratch/x360_retail/default.pe.bin"
IMAGE_FIXED="${REPO_ROOT}/output/_scratch/x360_retail/default.pe_ghidra.bin"

# --- Outputs --------------------------------------------------------------
OUT_DIR="${REPO_ROOT}/output/_ghidra_x360_retail"
PROJECT_DIR="${OUT_DIR}/proj"
PROJECT_NAME="mercs2xenon_retail"
DECOMP_RAW="${OUT_DIR}/xenon_retail_decomp.c"
DECOMP_NAMED="${OUT_DIR}/xenon_retail_decomp_named.c"
RUN_LOG="${OUT_DIR}/run.log"

# --- Toolchain (bundled, per CLAUDE.md) -----------------------------------
export JAVA_HOME="${REPO_ROOT}/tools/jdk21/jdk-21.0.11+10"
GHIDRA_HOME="${REPO_ROOT}/tools/ghidra_12.1_PUBLIC"
HEADLESS="${GHIDRA_HOME}/support/analyzeHeadless.bat"
SCRIPT_PATH="${REPO_ROOT}/tools/ghidra_x360"

# --- Runtime knobs --------------------------------------------------------
export MAXMEM="${MAXMEM:-8G}"
ANALYSIS_TIMEOUT="${GHIDRA_ANALYSIS_TIMEOUT:-14400}"
SKIP_FIX_PE="${SKIP_FIX_PE:-0}"
# Opt-in verbose logging. Set GHIDRA_LOG_CONFIG=<path/to/log4j2.xml> to promote
# selected Ghidra loggers to DEBUG. See tools/ghidra_x360/log4j2-verbose.xml.
GHIDRA_LOG_CONFIG="${GHIDRA_LOG_CONFIG:-}"

# --- Preflight checks -----------------------------------------------------
_die() { echo "error: $*" >&2; exit 1; }

[[ -f "$IMAGE_PATH" ]] \
  || _die "missing image: $IMAGE_PATH — see docs/reverse_engineer/exe_images.md xenon_retail_jtag_pe"
[[ -x "${JAVA_HOME}/bin/java.exe" || -x "${JAVA_HOME}/bin/java" ]] \
  || _die "bundled JDK not found at $JAVA_HOME (expected tools/jdk21/jdk-21.0.11+10/)"
[[ -f "$HEADLESS" ]] \
  || _die "analyzeHeadless.bat not found at $HEADLESS (expected tools/ghidra_12.1_PUBLIC/support/)"
[[ -f "${REPO_ROOT}/tools/fix_xbox_pe_for_ghidra.py" ]] \
  || _die "fix_xbox_pe_for_ghidra.py not found in tools/"
for js in CreateFunctions.java DecompileExport.java NameFromStrings.java; do
  [[ -f "${SCRIPT_PATH}/${js}" ]] || _die "Ghidra script missing: ${SCRIPT_PATH}/${js}"
done
if [[ -n "$GHIDRA_LOG_CONFIG" ]]; then
  [[ -f "$GHIDRA_LOG_CONFIG" ]] || _die "GHIDRA_LOG_CONFIG points at missing file: $GHIDRA_LOG_CONFIG"
  export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:-} -Dlog4j.configurationFile=${GHIDRA_LOG_CONFIG}"
fi

# --- Preview --------------------------------------------------------------
mkdir -p "$OUT_DIR" "$PROJECT_DIR"
cat <<EOF
================================================================
 Ghidra headless — Xbox 360 retail (image_id: xenon_retail_jtag_pe)
================================================================
  Input PE:        $IMAGE_PATH
  Fixed PE:        $IMAGE_FIXED
  Project dir:     $PROJECT_DIR
  Project name:    $PROJECT_NAME
  Decomp (raw):    $DECOMP_RAW
  Decomp (named):  $DECOMP_NAMED
  Run log:         $RUN_LOG

  JAVA_HOME:       $JAVA_HOME
  Ghidra home:     $GHIDRA_HOME
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
  echo "[1/2] Fixing PE for Ghidra loader (rewriting PointerToRawData = VirtualAddress)..."
  python "${REPO_ROOT}/tools/fix_xbox_pe_for_ghidra.py" "$IMAGE_PATH" "$IMAGE_FIXED"
  echo "     -> $IMAGE_FIXED"
else
  echo "[1/2] Fixed PE up-to-date — skipping fix pass."
fi

# --- Step 2: Headless import + analyze + export + name ------------------
echo "[2/2] Ghidra headless run (this will take hours; tail the run.log for progress)..."
echo ""

"$HEADLESS" \
  "$PROJECT_DIR" "$PROJECT_NAME" \
  -import "$IMAGE_FIXED" \
  -overwrite \
  -processor "PowerPC:BE:64:A2ALT-32addr" \
  -loader PeLoader \
  -analysisTimeoutPerFile "$ANALYSIS_TIMEOUT" \
  -scriptPath "$SCRIPT_PATH" \
  -preScript CreateFunctions.java \
  -postScript DecompileExport.java "$DECOMP_RAW" \
  -postScript NameFromStrings.java \
  -postScript DecompileExport.java "$DECOMP_NAMED" \
  < /dev/null 2>&1 | tee "$RUN_LOG"

echo ""
echo "================================================================"
echo " Done. Summary:"
echo "   Project:        $PROJECT_DIR/$PROJECT_NAME.rep"
echo "   Decomp (raw):   $DECOMP_RAW"
echo "   Decomp (named): $DECOMP_NAMED"
echo "   Run log:        $RUN_LOG"
echo ""
echo " Next:"
echo "   1. Update docs/data/exe_images.json  xenon_retail_jtag_pe.decomp"
echo "      with the paths above + function_count from run log."
echo "   2. Follow-up run adds RttiNameCtors (needs per-image rtti_vtables.txt)."
echo "================================================================"
