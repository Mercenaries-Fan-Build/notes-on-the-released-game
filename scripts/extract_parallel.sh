#!/usr/bin/env bash
#
# Parallel batch-extract Mercenaries 2 sges blocks from paths.txt.
# Uses xargs -P for process-level parallelism (each block is independent).
#
# Usage:
#   ./scripts/extract_parallel.sh output/extracted/ffcs_vz [JOBS]
#
# JOBS defaults to min(32, CPU count). Set SKIP_EXISTING=1 to skip done blocks.
# Prefer extract_all_from_paths.sh (default bulk sges: one Python, one mmap) for
# full packs; this script is a thin parallel wrapper for ad-hoc runs.

set -uo pipefail

die() { echo "error: $*" >&2; exit 1; }

FFCS_DIR="${1:?usage: $0 <ffcs-dir> [jobs]}"
_ncpu="$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)"
if [[ -n "${2:-}" ]]; then
  JOBS="$2"
else
  JOBS="$_ncpu"
  [[ "$JOBS" -gt 32 ]] && JOBS=32
  [[ "$JOBS" -lt 1 ]] && JOBS=1
fi

SKIP_EXISTING="${SKIP_EXISTING:-1}"

[[ -d "$FFCS_DIR" ]] || die "not a directory: $FFCS_DIR"
DATA_BIN="$FFCS_DIR/data.bin"
PATHS_TXT="$FFCS_DIR/paths.txt"
[[ -f "$DATA_BIN" ]] || die "missing $DATA_BIN"
[[ -f "$PATHS_TXT" ]] || die "missing $PATHS_TXT"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -z "${PYTHON:-}" ]]; then
  if [[ -x "$REPO_ROOT/.venv/bin/python" ]]; then
    PYTHON="$REPO_ROOT/.venv/bin/python"
  else
    PYTHON="python3"
  fi
fi
SGES="$REPO_ROOT/tools/sges_decompress.py"
[[ -f "$SGES" ]] || die "missing $SGES"

OUT_BASE="${EXTRACT_OUT_ROOT:-$REPO_ROOT/output/extracted}"

NAME="$(basename "$FFCS_DIR")"
NAME_LOWER="$(printf '%s' "$NAME" | tr '[:upper:]' '[:lower:]')"
PACK_ID="${NAME_LOWER#ffcs_}"
BATCH_SUB="batch_${PACK_ID}"

OUT_ROOT="$OUT_BASE/$BATCH_SUB"
BLOCK_DIR="$OUT_ROOT/blocks"
LOG_DIR="$OUT_ROOT/logs"
mkdir -p "$BLOCK_DIR" "$LOG_DIR"

RUN_ID="$(date +%Y%m%d-%H%M%S)"
LOG="$LOG_DIR/parallel-${RUN_ID}.log"
FAIL="$LOG_DIR/parallel-${RUN_ID}-failures.txt"
touch "$FAIL"

total=$(grep -cve '^[[:space:]]*$' "$PATHS_TXT" || true)
echo "Parallel extract: $total blocks, $JOBS workers"
echo "Output: $BLOCK_DIR"
echo "Log: $LOG"

extract_one() {
    local idx="$1" line="$2"
    local safe
    # Must match scripts/extract_all_from_paths.sh filename sanitization.
    safe=$(echo "$line" | tr '\\' '/' | sed 's|^\./||; s|/|__|g' | sed 's|[^A-Za-z0-9._-]|_|g')
    local out_bin="$BLOCK_DIR/$(printf '%05d' "$idx")_${safe}.bin"

    if [[ "$SKIP_EXISTING" == "1" ]] && [[ -f "$out_bin" ]]; then
        return 0
    fi

    if "$PYTHON" "$SGES" \
        --data-bin "$DATA_BIN" \
        --ffcs-out "$FFCS_DIR" \
        --index "$idx" \
        --out "$out_bin" >>"$LOG" 2>&1
    then
        echo "[OK $idx]"
    else
        echo "FAILED idx=$idx path=$line" >>"$FAIL"
        echo "[FAIL $idx]"
    fi
}
export -f extract_one
export PYTHON SGES DATA_BIN FFCS_DIR BLOCK_DIR SKIP_EXISTING LOG FAIL

idx=0
while IFS= read -r line || [[ -n "${line:-}" ]]; do
    [[ -z "${line//[[:space:]]/}" ]] && continue
    printf '%d\t%s\n' "$idx" "$line"
    idx=$((idx + 1))
done < "$PATHS_TXT" | xargs -P "$JOBS" -L 1 bash -c 'extract_one "$@"' _

echo ""
echo "Done. $total blocks dispatched with $JOBS workers."
if [[ -s "$FAIL" ]]; then
    fc=$(wc -l < "$FAIL")
    echo "Failures: $fc (see $FAIL)"
else
    echo "No failures."
fi
