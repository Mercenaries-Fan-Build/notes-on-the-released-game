#!/usr/bin/env bash
# scripts/ghidra_analyze_ps3_retail.sh
#
# Headless Ghidra decomp of the PS3 retail EBOOT.elf (decrypted PPC64 BE PPU).
# image_id ps3_engine_elf from docs/data/exe_images.json.
#
# Windows-first: uses the BUNDLED JDK + Ghidra in-repo, unlike
# scripts/ghidra_analyze_ps3_eboot.sh which targets macOS (brew/asdf).
#
# Writes to output/_ghidra_ps3_retail/ — a FRESH project, so the existing
# hand-curated analysis/cross_platform/ghidra_projects/Mercenaries2_PS3_EBOOT
# state (VZ.WAD RE targets, FxArchiveStoreFile vtable, etc.) is preserved
# as an independent reference.
#
# Usage (from repo root, in Git Bash):
#   ./scripts/ghidra_analyze_ps3_retail.sh
#
# Env knobs (all optional):
#   MAXMEM                  Ghidra Java heap (default 8G)
#   GHIDRA_ANALYSIS_TIMEOUT Per-file analysis timeout in seconds (default 21600 = 6h)
#
# Required env:
#   GHIDRA_THREADS          ExportFunctions.java decompiler threads (-Dcpu.core.override)
#
# Pipeline:
#   1. analyzeHeadless imports EBOOT.elf as PowerPC:BE:64:default, ElfLoader
#   2. -preScript SeedOpdFunctions.java <opdStart> <opdSize> <tocR2> analyze
#      Section names are STRIPPED in the PS3 EBOOT, so Ghidra never
#      auto-identifies .opd. We pass its coords (verified from readelf +
#      byte-peek) so the seeder can walk the 39,676-entry function-descriptor
#      table AND paint r2=TOC across executable blocks.
#   3. Auto-analyze runs (now over the full seeded function set)
#   4. -postScript ExportFunctions.java writes the raw-name export (FUN names)
#   5. -postScript NameFromStrings.java applies string-anchored names
#   6. -postScript ExportFunctions.java writes the named export
#   ExportFunctions stops unless the program's sha256 is images.tsv's ps3-v100 sha256; its call
#   lists read output/_exemap_exports/ps3-v100.imports.tsv.
#
# .opd + TOC coords (Section 24, verified 2026-09-07):
#   opd_va   = 0x00ff93b8
#   opd_size = 0x0004d7e0     (39,676 entries at 8 B each)
#   toc_r2   = 0x0104eb98     (single canonical TOC for the process)
#
# NOT run (follow-up):
#   - RttiNameCtors.java (needs per-image rtti_vtables.txt)

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# --- Inputs ---------------------------------------------------------------
IMAGE_PATH="${REPO_ROOT}/output/analysis/cross_platform/ps3_eboot/EBOOT.elf"

# --- Outputs --------------------------------------------------------------
OUT_DIR="${REPO_ROOT}/output/_ghidra_ps3_retail"
PROJECT_DIR="${OUT_DIR}/proj"
PROJECT_NAME="mercs2cell_retail"
IMAGE_ID="ps3-v100"
DECOMP_RAW="${OUT_DIR}/ps3_retail.functions_raw.jsonl"
DECOMP_NAMED="${OUT_DIR}/ps3_retail.functions.jsonl"
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
# Opt-in verbose logging. Set GHIDRA_LOG_CONFIG=<path/to/log4j2.xml> to promote
# selected Ghidra loggers to DEBUG. See tools/ghidra_x360/log4j2-verbose.xml.
GHIDRA_LOG_CONFIG="${GHIDRA_LOG_CONFIG:-}"

# --- Preflight ------------------------------------------------------------
_die() { echo "error: $*" >&2; exit 1; }
[[ -f "$IMAGE_PATH" ]]  || _die "missing EBOOT.elf at $IMAGE_PATH"
[[ -x "${JAVA_HOME}/bin/java.exe" || -x "${JAVA_HOME}/bin/java" ]] \
  || _die "bundled JDK not found at $JAVA_HOME"
[[ -f "$HEADLESS" ]]    || _die "analyzeHeadless.bat not found at $HEADLESS"
for js in SeedOpdFunctionsNoDisasm.java NameFromStrings.java; do
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

# .opd coords for the PS3 EBOOT.elf (verified against readelf + byte-peek)
OPD_VA="0x00ff93b8"
OPD_SIZE="0x0004d7e0"

mkdir -p "$OUT_DIR" "$PROJECT_DIR"
cat <<EOF
================================================================
 Ghidra headless — PS3 retail (image_id: ps3_engine_elf)
================================================================
  Input ELF:       $IMAGE_PATH
  Project dir:     $PROJECT_DIR
  Project name:    $PROJECT_NAME
  Decomp (raw):    $DECOMP_RAW
  Decomp (named):  $DECOMP_NAMED
  Run log:         $RUN_LOG

  JAVA_HOME:       $JAVA_HOME
  MAXMEM:          $MAXMEM
  Analysis timeout: ${ANALYSIS_TIMEOUT}s
  Log config:      ${GHIDRA_LOG_CONFIG:-(default — INFO)}
  Processor:       PowerPC:BE:64:default
  Loader:          ElfLoader
================================================================
EOF

echo "[1/1] Ghidra headless run..."
echo ""

"$HEADLESS" \
  "$PROJECT_DIR" "$PROJECT_NAME" \
  -import "$IMAGE_PATH" \
  -overwrite \
  -processor "PowerPC:BE:64:default" \
  -loader ElfLoader \
  -analysisTimeoutPerFile "$ANALYSIS_TIMEOUT" \
  -scriptPath "$SCRIPT_PATH;$EXPORT_SCRIPT_PATH" \
  -preScript SeedOpdFunctionsNoDisasm.java "$OPD_VA" "$OPD_SIZE" \
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
echo ""
echo " Next:"
echo "   1. Update docs/data/exe_images.json  ps3_engine_elf.decomp"
echo "   2. If fn count << 18MB image would suggest, write CreateFunctionsPS3.java"
echo "      to seed from .opd descriptor table (follow-up)."
echo "================================================================"
