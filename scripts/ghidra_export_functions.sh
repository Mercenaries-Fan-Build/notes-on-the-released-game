#!/usr/bin/env bash
# scripts/ghidra_export_functions.sh <image_id>...
#
# For each image id, opens the image's saved Ghidra project read-only (-readOnly -noanalysis) and
# runs scripts/ghidra_scripts/ExportFunctions.java, writing
# output/_ghidra_exports/<image_id>.functions.jsonl and its log output/_ghidra_exports/<image_id>.log.
#
# Inputs, all required (a missing one stops the script before any image runs):
#   tools/wad_simulator/.mercs2-local.toml  key ghidra_headless = "<path to analyzeHeadless>"
#                                           (the machine-local, git-ignored config of
#                                           tools/wad_simulator/scripts/find-vz-wad.sh)
#   tools/wad_simulator/crates/mercs2_exemap/data/images.tsv
#                                           the image's sha256 (passed to ExportFunctions, which
#                                           stops when the program's executable differs) and its
#                                           code_image; an image whose code_image is not "-"
#                                           shares that image's code and is refused
#   scripts/ghidra_projects.tsv             the image's project dir, project name, program,
#                                           Ghidra settings dir ("-" for the default) and imports
#                                           sidecar ("-" for none), as repo-relative paths; its
#                                           code_blocks column is FnMnemonicSig.java's
#                                           <codeBlocks> argument for the image (the export
#                                           covers every function and does not read it)
#   scripts/ghidra_scripts/pe_import_ordinals.tsv  the ordinal table
#   GHIDRA_HEADLESS_MAXMEM                  environment: the headless Java heap (e.g. 32G); this is
#                                           the variable analyzeHeadless reads (it ignores MAXMEM)
#   GHIDRA_THREADS                          environment: decompiler threads, passed as
#                                           -Dcpu.core.override=<n>
# The tables are read by scripts/ghidra_tables.sh.
#
# A previous <image_id>.functions.jsonl is removed before its image runs. ExportFunctions writes
# the file only after its end record, so the file exists exactly when the export completed; the
# script stops at the first image whose file is missing afterwards or whose log reports a script
# error (analyzeHeadless exits 0 when a script throws).
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/ghidra_tables.sh
source "$REPO_ROOT/scripts/ghidra_tables.sh"
ORDINALS="$REPO_ROOT/scripts/ghidra_scripts/pe_import_ordinals.tsv"
SCRIPTS="$REPO_ROOT/scripts/ghidra_scripts"
OUT_DIR="$REPO_ROOT/output/_ghidra_exports"

die() { echo "ghidra_export_functions: $*" >&2; exit 1; }

[[ $# -ge 1 ]] || die "usage: scripts/ghidra_export_functions.sh <image_id>..."
[[ -n "${GHIDRA_HEADLESS_MAXMEM:-}" ]] || die "GHIDRA_HEADLESS_MAXMEM (the headless Java heap, e.g. 32G) is not set"
[[ "${GHIDRA_THREADS:-}" =~ ^[1-9][0-9]*$ ]] \
  || die "GHIDRA_THREADS (decompiler threads, a positive integer) is '${GHIDRA_THREADS:-}'"

HEADLESS=$(ghidra_headless_path) || die "no analyzeHeadless (see above)"
[[ -f "$ORDINALS" ]] || die "missing ordinal table $ORDINALS"

# Resolve and check every image before running any.
declare -a IDS SHAS PDIRS PNAMES PROGS SETS IMPS
for id in "$@"; do
  sha=$(image_export_sha256 "$id") || die "image $id refused"
  prow=$(ghidra_project_row "$id") || die "image $id refused"
  pdir=$(ghidra_field "$prow" 2); pname=$(ghidra_field "$prow" 3); prog=$(ghidra_field "$prow" 4)
  set_dir=$(ghidra_field "$prow" 5); imports=$(ghidra_field "$prow" 6)
  [[ -f "$REPO_ROOT/$pdir/$pname.gpr" ]] || die "$id: no Ghidra project $REPO_ROOT/$pdir/$pname.gpr"
  if [[ "$set_dir" != "-" ]]; then
    [[ -d "$REPO_ROOT/$set_dir" ]] || die "$id: settings dir $REPO_ROOT/$set_dir does not exist"
  fi
  if [[ "$imports" != "-" ]]; then
    [[ -f "$REPO_ROOT/$imports" ]] || die "$id: imports sidecar $REPO_ROOT/$imports does not exist"
  fi
  IDS+=("$id"); SHAS+=("$sha"); PDIRS+=("$pdir"); PNAMES+=("$pname"); PROGS+=("$prog")
  SETS+=("$set_dir"); IMPS+=("$imports")
done

mkdir -p "$OUT_DIR"
for i in "${!IDS[@]}"; do
  id="${IDS[$i]}"
  out="$OUT_DIR/$id.functions.jsonl"
  log="$OUT_DIR/$id.log"
  if [[ -e "$out" ]]; then
    echo "removing the previous $out"
    rm "$out"
  fi
  opts="-Dcpu.core.override=$GHIDRA_THREADS"
  [[ "${SETS[$i]}" == "-" ]] || opts="-Dapplication.settingsdir=$REPO_ROOT/${SETS[$i]} $opts"
  imports="${IMPS[$i]}"
  [[ "$imports" == "-" ]] || imports="$REPO_ROOT/$imports"
  echo "== $id: $REPO_ROOT/${PDIRS[$i]} ${PNAMES[$i]} ${PROGS[$i]} -> $out (log $log)"
  start=$(date +%s)
  GHIDRA_HEADLESS_JAVA_OPTIONS="$opts" GHIDRA_HEADLESS_MAXMEM="$GHIDRA_HEADLESS_MAXMEM" "$HEADLESS" \
    "$REPO_ROOT/${PDIRS[$i]}" "${PNAMES[$i]}" -process "${PROGS[$i]}" -readOnly -noanalysis \
    -scriptPath "$SCRIPTS" \
    -postScript ExportFunctions.java "$id" "${SHAS[$i]}" "$out" "$ORDINALS" "$imports" \
    < /dev/null 2>&1 | tee "$log"
  if grep -q "REPORT SCRIPT ERROR" "$log"; then
    die "$id: ExportFunctions.java stopped; see $log"
  fi
  [[ -f "$out" ]] || die "$id: $out was not written; see $log"
  echo "== $id: done in $(( $(date +%s) - start )) s -> $out"
done
