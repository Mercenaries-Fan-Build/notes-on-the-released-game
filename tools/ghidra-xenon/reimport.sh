#!/usr/bin/env bash
# Import one Xbox 360 PE into a NEW Ghidra project with PowerPC:BE:64:Xenon, using the seeded
# pipeline of the existing _ghidra_x360* projects (CreateFunctions preScript; ExportFunctions,
# NameFromStrings, ExportFunctions postScripts), with RecoverReferencedTables (notes repo
# scripts/ghidra_scripts) as the first postScript; its log is <outDir>/recover_tables.log and its
# forensic ledger <outDir>/recover_tables_ledger.tsv.
# ExportFunctions (notes repo scripts/ghidra_scripts) writes <outDir>/<decompPrefix>.functions_raw.jsonl
# before naming and <outDir>/<decompPrefix>.functions.jsonl after; it stops unless the program's
# sha256 is the notes repo images.tsv sha256 of <imageId>, and its call lists read <importsTsv>
# (`exemap imports`). GHIDRA_THREADS (required) is its decompiler thread count; GHIDRA_HEADLESS_MAXMEM
# (required) the headless Java heap. analyzeHeadless is the `ghidra_headless` key of
# tools/wad_simulator/.mercs2-local.toml (scripts/ghidra_tables.sh).
# The extension is loaded from a settings dir
# inside the output dir (-Dapplication.settingsdir), so the Ghidra install and the user's
# settings are untouched. No analysis timeout.
# Usage: reimport.sh <extensionZip> <inputPE> <funcStarts> <rttiTsv> <outDir> <projectName> <decompPrefix> <imageId> <importsTsv>
set -euo pipefail
[ $# -eq 9 ] || { echo "usage: reimport.sh <extensionZip> <inputPE> <funcStarts> <rttiTsv> <outDir> <projectName> <decompPrefix> <imageId> <importsTsv>" >&2; exit 2; }
ZIP="$1"; IN="$2"; STARTS="$3"; RTTI="$4"; OUT="$5"; PNAME="$6"; PREFIX="$7"; IMAGE_ID="$8"; IMPORTS="$9"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
X360_SCRIPTS="$REPO_ROOT/tools/ghidra_x360"
GHIDRA_SCRIPTS="$REPO_ROOT/scripts/ghidra_scripts"
[ -f "$GHIDRA_SCRIPTS/RecoverReferencedTables.java" ] || { echo "missing RecoverReferencedTables.java in $GHIDRA_SCRIPTS" >&2; exit 2; }
[ -f "$X360_SCRIPTS/CreateFunctions.java" ] || { echo "missing CreateFunctions.java in $X360_SCRIPTS" >&2; exit 2; }
[ -f "$ZIP" ] || { echo "missing extension zip: $ZIP" >&2; exit 2; }
[ -f "$IN" ] || { echo "missing input: $IN" >&2; exit 2; }
[ -f "$STARTS" ] || { echo "missing func starts: $STARTS" >&2; exit 2; }
[ -f "$RTTI" ] || { echo "missing rtti sidecar: $RTTI" >&2; exit 2; }
[ -f "$GHIDRA_SCRIPTS/ExportFunctions.java" ] || { echo "missing ExportFunctions.java in $GHIDRA_SCRIPTS" >&2; exit 2; }
[ -f "$IMPORTS" ] || { echo "missing imports sidecar: $IMPORTS" >&2; exit 2; }
[[ "${GHIDRA_THREADS:-}" =~ ^[1-9][0-9]*$ ]] || { echo "GHIDRA_THREADS (decompiler threads) is '${GHIDRA_THREADS:-}'" >&2; exit 2; }
[ -n "${GHIDRA_HEADLESS_MAXMEM:-}" ] || { echo "GHIDRA_HEADLESS_MAXMEM (the headless Java heap, e.g. 16G) is not set" >&2; exit 2; }
# shellcheck source=scripts/ghidra_tables.sh
source "$REPO_ROOT/scripts/ghidra_tables.sh"
IMAGE_SHA=$(image_export_sha256 "$IMAGE_ID") || { echo "no images.tsv sha256 for $IMAGE_ID" >&2; exit 2; }
HEADLESS=$(ghidra_headless_path) || exit 2
USER_SETTINGS=$(ghidra_user_settings_subdir "$HEADLESS") || exit 2
[ -e "$OUT" ] && { echo "output dir already exists: $OUT" >&2; exit 2; }

SET="$OUT/ghidra_settings"
mkdir -p "$OUT/proj" "$SET/$USER_SETTINGS/Extensions" "$OUT/ghidra_cache" "$OUT/ghidra_tmp"
(cd "$SET/$USER_SETTINGS/Extensions" && unzip -q "$ZIP")
cp "$STARTS" "$OUT/func_starts.txt"

export GHIDRA_HEADLESS_JAVA_OPTIONS="-Dapplication.settingsdir=$SET -Dapplication.cachedir=$OUT/ghidra_cache -Dapplication.tempdir=$OUT/ghidra_tmp -Dcpu.core.override=$GHIDRA_THREADS"
ORDINALS="$GHIDRA_SCRIPTS/pe_import_ordinals.tsv"

exec "$HEADLESS" "$OUT/proj" "$PNAME" \
  -import "$IN" -processor PowerPC:BE:64:Xenon \
  -scriptPath "$X360_SCRIPTS;$GHIDRA_SCRIPTS" \
  -preScript CreateFunctions.java "$OUT/func_starts.txt" "$OUT/create_functions.tsv" split \
  -postScript RecoverReferencedTables.java "$OUT/recover_tables.log" "$RTTI" "$OUT/recover_tables_ledger.tsv" \
  -postScript ExportFunctions.java "$IMAGE_ID" "$IMAGE_SHA" "$OUT/${PREFIX}.functions_raw.jsonl" "$ORDINALS" "$IMPORTS" \
  -postScript NameFromStrings.java \
  -postScript ExportFunctions.java "$IMAGE_ID" "$IMAGE_SHA" "$OUT/${PREFIX}.functions.jsonl" "$ORDINALS" "$IMPORTS"
