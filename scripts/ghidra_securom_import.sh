#!/usr/bin/env bash
# scripts/ghidra_securom_import.sh
#
# Step 1 of the SecuROM code recovery: import one PC executable into a new, persistent Ghidra
# project of its own with the default loader options and Ghidra's default auto-analysis, and save
# it. The project directory must not exist yet (each project starts from a clean import).
#
# Usage:
#   ghidra_securom_import.sh <analyzeHeadless> <javaHome> <asdfJavaVersion> <maxMem> <projectDir> <projectName> <exe> <log>
#     analyzeHeadless  path of Ghidra's support/analyzeHeadless
#     javaHome         JDK used by Ghidra (exported as JAVA_HOME)
#     asdfJavaVersion  asdf java version (exported as ASDF_JAVA_VERSION). Ghidra's launch.sh runs
#                      the first `java` on PATH before JAVA_HOME (support/launch.sh:128-133); when
#                      that is the asdf shim, the shim needs this to pick a JDK without a
#                      .tool-versions entry
#     maxMem           Ghidra heap (exported as GHIDRA_HEADLESS_MAXMEM), e.g. 24G
#     projectDir       directory created for the project; must not exist
#     projectName      Ghidra project name
#     exe              executable to import
#     log              Ghidra application log written by -log; must not exist
#
# analyzeHeadless exits 0 when an import fails, so success is decided from the log: it must exist
# and hold "REPORT: Analysis succeeded for file: file://<exe>", "REPORT: Save succeeded for:
# /<exe name>" and "REPORT: Import succeeded". analyzeHeadless's exit status is printed; a
# non-zero status, a missing log or a missing line prints a "FAILED:" line naming the cause and
# exits 1.
set -euo pipefail

if [[ $# -ne 8 ]]; then
  echo "usage: $0 <analyzeHeadless> <javaHome> <asdfJavaVersion> <maxMem> <projectDir> <projectName> <exe> <log>" >&2
  exit 2
fi
HEADLESS="$1"; JAVA_HOME_ARG="$2"; ASDF_JAVA_ARG="$3"; MAXMEM_ARG="$4"; PROJ_DIR="$5"; PROJ_NAME="$6"; EXE="$7"; LOG="$8"

[[ -x "$HEADLESS" ]] || { echo "error: analyzeHeadless not executable: $HEADLESS" >&2; exit 2; }
[[ -x "$JAVA_HOME_ARG/bin/java" ]] || { echo "error: no bin/java under javaHome $JAVA_HOME_ARG" >&2; exit 2; }
[[ -n "$ASDF_JAVA_ARG" ]] || { echo "error: asdfJavaVersion is empty" >&2; exit 2; }
[[ -f "$EXE" ]] || { echo "error: executable not found: $EXE" >&2; exit 2; }
[[ ! -e "$PROJ_DIR" ]] || { echo "error: project directory already exists: $PROJ_DIR" >&2; exit 2; }
[[ -d "$(dirname "$LOG")" ]] || { echo "error: log directory does not exist: $(dirname "$LOG")" >&2; exit 2; }
[[ ! -e "$LOG" ]] || { echo "error: log already exists: $LOG" >&2; exit 2; }

export JAVA_HOME="$JAVA_HOME_ARG"
export ASDF_JAVA_VERSION="$ASDF_JAVA_ARG"
export GHIDRA_HEADLESS_MAXMEM="$MAXMEM_ARG"
PROG="$(basename "$EXE")"

mkdir -p "$PROJ_DIR"
date -u +"import start %FT%TZ"
rc=0
"$HEADLESS" "$PROJ_DIR" "$PROJ_NAME" -import "$EXE" -log "$LOG" < /dev/null || rc=$?
date -u +"import end %FT%TZ"
echo "analyzeHeadless exit status $rc"

if [[ $rc -ne 0 ]]; then
  echo "FAILED: analyzeHeadless exited with status $rc"
  exit 1
fi
if [[ ! -f "$LOG" ]]; then
  echo "FAILED: analyzeHeadless wrote no log at $LOG"
  exit 1
fi
for want in "REPORT: Analysis succeeded for file: file://$EXE" "REPORT: Save succeeded for: /$PROG" "REPORT: Import succeeded"; do
  if ! grep -qF "$want" "$LOG"; then
    echo "FAILED: import log $LOG lacks \"$want\""
    exit 1
  fi
done
echo "import OK: $PROJ_DIR/$PROJ_NAME /$PROG"
