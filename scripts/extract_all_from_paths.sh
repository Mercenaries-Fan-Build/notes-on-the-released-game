#!/usr/bin/env bash
#
# Batch-extract every Mercenaries 2 .block listed in paths.txt by index (same order as sges in data.bin).
#
# Usage:
#   ./scripts/extract_all_from_paths.sh output/extracted/ffcs_vz
#   ./scripts/extract_all_from_paths.sh output/extracted/ffcs_shell --max 5
#   START=100 MAX=50 ./scripts/extract_all_from_paths.sh output/extracted/ffcs_vz
#
# Env:
#   PYTHON   Python interpreter (default: repo .venv/bin/python if present, else python3)
#   START    First line index (0-based, default 0)
#   MAX      Max number of blocks to process (default: all lines)
#   SKIP_EXISTING  If set to 1, skip when output file already exists
#   WITH_UCFX  If set to 1, run ucfx_parser on each .bin (slow at scale)
#   EXTRACT_OUT_ROOT  Parent directory for batch_* folders (default: <repo>/output/extracted)
#   ALLOW_PARTIAL     If set to 1, exit 0 even when some blocks failed (see logs/*/failures.txt)
#   EXTRACT_JOBS      unset/0 = fast bulk (one Python, one mmap, all blocks); 1 = legacy one-process-per-block; N>1 = same as bulk (N ignored)
#
# Warning: output/ffcs_vz lists ~11k blocks; a full run writes tens of GB and takes a long time.
#          Use --max / START+MAX or SKIP_EXISTING=1 for incremental work.
#

set -uo pipefail

START="${START:-0}"
MAX="${MAX:-}"
SKIP_EXISTING="${SKIP_EXISTING:-0}"
WITH_UCFX="${WITH_UCFX:-0}"
ALLOW_PARTIAL="${ALLOW_PARTIAL:-0}"

die() { echo "error: $*" >&2; exit 1; }

FFCS_DIR="${1:?usage: $0 <path-to-ffcs-output-dir e.g. output/ffcs_vz> [--max N]}"

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --max) MAX="$2"; shift 2 ;;
    --start) START="$2"; shift 2 ;;
    *) die "unknown arg: $1" ;;
  esac
done

[[ -d "$FFCS_DIR" ]] || die "not a directory: $FFCS_DIR"
DATA_BIN="$FFCS_DIR/data.bin"
PATHS_TXT="$FFCS_DIR/paths.txt"
[[ -f "$DATA_BIN" ]] || die "missing $DATA_BIN (run mercs2_ffcs_extract.py first)"
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
UCFX="$REPO_ROOT/tools/ucfx_parser.py"
[[ -f "$SGES" ]] || die "missing $SGES"

OUT_BASE="${EXTRACT_OUT_ROOT:-$REPO_ROOT/output/extracted}"

# Mirror ffcs_<pack> -> batch_<pack> (case-insensitive ffcs_ prefix; lowercase pack for stable dirs).
# e.g. ffcs_vz → batch_vz, ffcs_Loading → batch_loading, ffcs_English → batch_english
NAME="$(basename "$FFCS_DIR")"
NAME_LOWER="$(printf '%s' "$NAME" | tr '[:upper:]' '[:lower:]')"
if [[ "$NAME_LOWER" != ffcs_* ]]; then
  die "expected FFCS folder named ffcs_<pack>, got: $NAME"
fi
PACK_ID="${NAME_LOWER#ffcs_}"
[[ -n "$PACK_ID" ]] || die "missing pack id in folder name: $NAME"
BATCH_SUB="batch_${PACK_ID}"

OUT_ROOT="$OUT_BASE/$BATCH_SUB"
BLOCK_DIR="$OUT_ROOT/blocks"
UCFX_DIR="$OUT_ROOT/ucfx_manifests"
LOG_DIR="$OUT_ROOT/logs"
mkdir -p "$BLOCK_DIR" "$UCFX_DIR" "$LOG_DIR"

RUN_ID="$(date +%Y%m%d-%H%M%S)"
LOG="$LOG_DIR/run-${RUN_ID}.log"
FAIL="$LOG_DIR/run-${RUN_ID}-failures.txt"
echo "Logging to $LOG"

total_lines=$(grep -cve '^[[:space:]]*$' "$PATHS_TXT" || true)
echo "paths.txt non-empty lines: $total_lines"

EXTRACT_JOBS_RAW="${EXTRACT_JOBS:-}"
if [[ "${EXTRACT_JOBS_RAW}" == "1" ]]; then
  EXTRACT_MODE="sequential"
  echo "EXTRACT_JOBS=1 — sequential sges (one Python process per block)" | tee -a "$LOG"
else
  EXTRACT_MODE="bulk"
  if [[ -n "${EXTRACT_JOBS_RAW}" ]] && [[ "${EXTRACT_JOBS_RAW}" != "0" ]]; then
    [[ "${EXTRACT_JOBS_RAW}" =~ ^[0-9]+$ ]] || die "EXTRACT_JOBS must be 0, 1, or a positive integer, got: $EXTRACT_JOBS_RAW"
    echo "EXTRACT_JOBS=$EXTRACT_JOBS_RAW — bulk sges (parallel worker count ignored; use EXTRACT_JOBS=1 for per-block mode)" | tee -a "$LOG"
  else
    echo "EXTRACT_JOBS unset/0 — bulk sges (single Python, one mmap, all blocks)" | tee -a "$LOG"
  fi
fi

idx=0
count=0
processed=0

if [[ "$EXTRACT_MODE" == "sequential" ]]; then
  # Same filtering as tools/sges_decompress.py load_paths(): skip empty/whitespace-only lines.
  while IFS= read -r line || [[ -n "${line:-}" ]]; do
    [[ -z "${line//[[:space:]]/}" ]] && continue

    if [[ "$idx" -lt "$START" ]]; then
      idx=$((idx + 1))
      continue
    fi

    if [[ -n "${MAX:-}" ]] && [[ "$processed" -ge "$MAX" ]]; then
      break
    fi

    safe=$(echo "$line" | tr '\\' '/' | sed 's|^\./||; s|/|__|g' | sed 's|[^A-Za-z0-9._-]|_|g')
    out_bin="$BLOCK_DIR/$(printf '%05d' "$idx")_${safe}.bin"

    if [[ "$SKIP_EXISTING" == "1" ]] && [[ -f "$out_bin" ]]; then
      echo "skip existing [$idx] $line" | tee -a "$LOG"
      idx=$((idx + 1))
      processed=$((processed + 1))
      continue
    fi

    echo "[$idx] -> $out_bin" | tee -a "$LOG"
    if "$PYTHON" "$SGES" \
        --data-bin "$DATA_BIN" \
        --ffcs-out "$FFCS_DIR" \
        --index "$idx" \
        --out "$out_bin" >>"$LOG" 2>&1
    then
      :
    else
      echo "FAILED idx=$idx path=$line" >>"$FAIL"
    fi

    if [[ "$WITH_UCFX" == "1" ]] && [[ -f "$out_bin" ]]; then
      "$PYTHON" "$UCFX" "$out_bin" --out "$UCFX_DIR/$(printf '%05d' "$idx")_${safe}.json" >>"$LOG" 2>&1 || echo "UCFX_FAIL idx=$idx" >>"$FAIL"
    fi

    idx=$((idx + 1))
    count=$((count + 1))
    processed=$((processed + 1))
  done < <(grep -v '^[[:space:]]*$' "$PATHS_TXT" || true)

  echo "Done. Processed $count blocks (start=$START max=${MAX:-all}). Outputs: $OUT_ROOT"
else
  : >"$FAIL"
  BULK_MANIFEST="$LOG_DIR/bulk_manifest-${RUN_ID}.json"
  BULK_ARGS=(
    "$PYTHON" "$SGES"
    --data-bin "$DATA_BIN"
    --paths "$PATHS_TXT"
    --bulk-out-dir "$BLOCK_DIR"
    --start "$START"
    --bulk-manifest "$BULK_MANIFEST"
    --failures-out "$FAIL"
  )
  [[ -n "${MAX:-}" ]] && BULK_ARGS+=(--max "$MAX")
  [[ "$SKIP_EXISTING" == "1" ]] && BULK_ARGS+=(--skip-existing)
  [[ "$WITH_UCFX" == "1" ]] && BULK_ARGS+=(--ucfx-out-dir "$UCFX_DIR")

  echo "Bulk sges decompress → $BLOCK_DIR" | tee -a "$LOG"
  "${BULK_ARGS[@]}" 2>&1 | tee -a "$LOG"
  ec=${PIPESTATUS[0]}
  if [[ "$ec" -ne 0 ]] && [[ "$ALLOW_PARTIAL" != "1" ]]; then
    echo "bulk sges reported failures (see $FAIL)" >&2
    exit 1
  fi
  echo "Done. Bulk pass finished (start=$START max=${MAX:-all}). Outputs: $OUT_ROOT"
fi

if [[ -s "$FAIL" ]]; then
  echo "Failures recorded in $FAIL" >&2
  if [[ "$ALLOW_PARTIAL" != "1" ]]; then
    exit 1
  fi
fi
