#!/usr/bin/env bash
#
# Full Mercenaries 2 pipeline from the retail zip only:
#   unzip → FFCS slices → batch sges decompress → stage 2 (UCFX / mesh / textures / Havok).
#
# Usage (options must appear before the zip path):
#   ./scripts/extract_from_zip.sh "/path/to/Mercenaries 2 World in Flames.zip"
#
# Default unzip / pipeline root (same directory as the zip):
#   .../<zip-dir>/output/
#     data/*.wad          (game files — single-root zips are merged here, no extra game-named folder)
#     extracted/ffcs_*    (FFCS slices)
#     extracted/batch_*   (batch sges outputs when enabled)
#     extracted/review/   (stage 2: ucfx / mesh / textures / Havok — Makefile runs build-texture-index then stage2_parallel.sh)
#
# Override destination with --out-dir PATH or env OUTPUT_DIR (absolute or relative paths OK).
#
# Default: **full** pipeline — batch-decompresses **every** data/*.wad (including vz), then stage 2.
#   --quick             Shell + loading only (skip vz & other heavy packs unless --decompress-vz)
#   --everything        Same as default full mode (retained for clarity / scripts)
#   --force-unzip       Remove existing output folder and unzip again
#   --skip-unzip        Use existing folder (must contain data/*.wad)
#   --decompress-all    Same as default (full); kept for compatibility
#   --decompress-vz     Only applies with --quick: also batch-decompress vz.wad
#   --no-decompress     Only FFCS extraction; skip sges batch step
#   --no-stage2         Skip stage 2 here (Makefile extract-all runs build-texture-index + review-all after)
#   --vz-max N          Cap vz batch size (full mode or quick + --decompress-vz)
#
# Env:
#   OUTPUT_DIR          Same as --out-dir if set (default root is <zip-directory>/output)
#   PYTHON  SKIP_EXISTING  WITH_UCFX  START  MAX  ALLOW_PARTIAL  EXTRACT_JOBS  (passed through to extract_all_from_paths.sh)
#           EXTRACT_JOBS: unset/0 = bulk sges (one Python, one mmap); 1 = one subprocess per block; N>1 = bulk (N ignored)
#           Default: repo .venv/bin/python if present and PYTHON unset, else python3
#   STAGE2_SEQUENTIAL=1   Run stage 2 one blob at a time (stage2_review_extract.sh) instead of parallel
#   STAGE2_JOBS=N         Second argument to stage2_parallel.sh (worker count); default is CPU-based
#

set -uo pipefail

die() { echo "error: $*" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -z "${PYTHON:-}" ]]; then
  if [[ -x "$REPO_ROOT/.venv/bin/python" ]]; then
    PYTHON="$REPO_ROOT/.venv/bin/python"
  else
    PYTHON="python3"
  fi
fi
EXTRACT_SCRIPT="$REPO_ROOT/scripts/extract_all_from_paths.sh"
STAGE2_SCRIPT="$REPO_ROOT/scripts/stage2_review_extract.sh"
STAGE2_PARALLEL_SCRIPT="$REPO_ROOT/scripts/stage2_parallel.sh"
FFCS_EXTRACT="$REPO_ROOT/tools/mercs2_ffcs_extract.py"

FORCE_UNZIP=0
SKIP_UNZIP=0
DECOMPRESS_MODE=full    # none | small | full  (default full = every .wad including vz)
INCLUDE_VZ=0
VZ_MAX=""
CUSTOM_OUT=""
NO_STAGE2=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out-dir|--output-dir)
      [[ -n "${2:-}" ]] || die "--out-dir requires a path"
      CUSTOM_OUT="$2"
      shift 2
      ;;
    --quick)
      DECOMPRESS_MODE=small
      shift
      ;;
    --everything)
      DECOMPRESS_MODE=full
      shift
      ;;
    --no-stage2) NO_STAGE2=1; shift ;;
    --force-unzip) FORCE_UNZIP=1; shift ;;
    --skip-unzip) SKIP_UNZIP=1; shift ;;
    --decompress-all) DECOMPRESS_MODE=full; shift ;;
    --decompress-vz) INCLUDE_VZ=1; shift ;;
    --no-decompress) DECOMPRESS_MODE=none; shift ;;
    --vz-max)
      [[ -n "${2:-}" ]] || die "--vz-max requires a number"
      VZ_MAX="$2"
      shift 2
      ;;
    -*)
      die "unknown option: $1"
      ;;
    *)
      break
      ;;
  esac
done

ZIP="${1:?usage: $0 [options] <Mercenaries 2 World in Flames.zip>}"

[[ "$SKIP_UNZIP" -eq 1 ]] && [[ "$FORCE_UNZIP" -eq 1 ]] && die "--skip-unzip and --force-unzip conflict"

[[ -f "$EXTRACT_SCRIPT" ]] || die "missing $EXTRACT_SCRIPT"
[[ -f "$STAGE2_SCRIPT" ]] || die "missing $STAGE2_SCRIPT"
[[ -f "$STAGE2_PARALLEL_SCRIPT" ]] || die "missing $STAGE2_PARALLEL_SCRIPT"
[[ -f "$FFCS_EXTRACT" ]] || die "missing $FFCS_EXTRACT"
if [[ "$SKIP_UNZIP" -ne 1 ]]; then
  [[ -f "$ZIP" ]] || die "not a file: $ZIP"
fi

ZIP_ABS="$(cd "$(dirname "$ZIP")" && pwd)/$(basename "$ZIP")"
PARENT="$(dirname "$ZIP_ABS")"

resolve_dest() {
  local p="$1"
  if [[ "$p" = /* ]]; then
    printf '%s' "$p"
  else
    printf '%s/%s' "$(pwd)" "$p"
  fi
}

if [[ -n "$CUSTOM_OUT" ]]; then
  DEST="$(resolve_dest "$CUSTOM_OUT")"
elif [[ -n "${OUTPUT_DIR:-}" ]]; then
  DEST="$(resolve_dest "$OUTPUT_DIR")"
else
  DEST="$PARENT/output"
fi

extract_zip_normalized() {
  local zipf="$1" dest="$2"
  local tmp
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/m2zip.XXXXXX")"
  cleanup_tmp() { rm -rf "$tmp"; }
  trap cleanup_tmp EXIT

  unzip -q -o "$zipf" -d "$tmp" || die "unzip failed"

  shopt -s nullglob
  local top=( "$tmp"/* )
  shopt -u nullglob

  if [[ ${#top[@]} -eq 0 ]]; then
    die "zip archive appears empty"
  fi

  rm -rf "$dest"
  mkdir -p "$dest"

  if [[ ${#top[@]} -eq 1 && -d "${top[0]}" ]]; then
    # Typical retail layout: one root folder — merge its contents into dest (no extra folder level).
    shopt -s dotglob nullglob
    local inner=( "${top[0]}"/* )
    shopt -u dotglob nullglob
    if [[ ${#inner[@]} -gt 0 ]]; then
      mv "${inner[@]}" "$dest/"
    fi
    rm -rf "${top[0]}"
  else
    mv "${top[@]}" "$dest/"
  fi

  trap - EXIT
  cleanup_tmp
}

if [[ "$SKIP_UNZIP" -eq 1 ]]; then
  [[ -d "$DEST" ]] || die "missing expected folder: $DEST (--skip-unzip)"
else
  if [[ -d "$DEST" ]] && [[ "$FORCE_UNZIP" -eq 1 ]]; then
    rm -rf "$DEST"
  fi
  if [[ ! -d "$DEST/data" ]]; then
    echo "Extracting zip → $DEST"
    extract_zip_normalized "$ZIP_ABS" "$DEST"
  else
    echo "Using existing output folder (data/ present): $DEST"
    echo "  Re-run with --force-unzip to replace, or --skip-unzip to silence this."
  fi
fi

[[ -d "$DEST/data" ]] || die "expected $DEST/data after unzip (is this the correct Mercenaries 2 zip?)"

shopt -s nullglob
WADS=( "$DEST/data"/*.wad )
shopt -u nullglob

[[ ${#WADS[@]} -gt 0 ]] || die "no .wad files in $DEST/data"

case "$DECOMPRESS_MODE" in
  full)
    echo "Full pipeline: batch-decompressing every data/*.wad pack (including vz). This may take a long time."
    ;;
  small)
    echo "Quick pipeline: shell + loading only (use default without --quick for everything)."
    ;;
  none) ;;
esac

EXT="$DEST/extracted"
mkdir -p "$EXT"

echo "FFCS extraction → $EXT/ffcs_<name>/"
for wad in "${WADS[@]}"; do
  stem="$(basename "$wad" .wad)"
  out="$EXT/ffcs_$stem"
  echo "  $stem.wad → $out"
  "$PYTHON" "$FFCS_EXTRACT" "$wad" --out "$out" || die "FFCS extract failed for $wad"
done

verify_full_batches() {
  local wad stem pack_lower fd bd
  local -a bins
  for wad in "${WADS[@]}"; do
    stem="$(basename "$wad" .wad)"
    pack_lower="$(printf '%s' "$stem" | tr '[:upper:]' '[:lower:]')"
    fd="$EXT/ffcs_$stem"
    bd="$EXT/batch_$pack_lower"
    [[ -d "$fd" && -f "$fd/paths.txt" ]] || continue
    shopt -s nullglob
    bins=( "$bd"/blocks/*.bin )
    shopt -u nullglob
    if [[ ${#bins[@]} -eq 0 ]]; then
      die "no .bin outputs for ${stem}.wad — expected ${bd}/blocks/*.bin. For vz-only resume: EXTRACT_OUT_ROOT=\"$EXT\" \"$EXTRACT_SCRIPT\" \"$fd\""
    fi
  done
}

run_batch() {
  local ffcs_dir="$1"
  local label="$2"
  shift 2
  echo "Batch sges decompress ($label): $ffcs_dir"
  EXTRACT_OUT_ROOT="$EXT" "$EXTRACT_SCRIPT" "$ffcs_dir" "$@" \
    || die "batch decompress failed for $ffcs_dir (see $ffcs_dir and ${EXT}/batch_*/logs/)"
}

VZ_EXTRA=()
[[ -n "$VZ_MAX" ]] && VZ_EXTRA+=( --max "$VZ_MAX" )

case "$DECOMPRESS_MODE" in
  none)
    echo "Skipping batch decompress (--no-decompress)."
    ;;
  small)
    for stem in shell loading; do
      d="$EXT/ffcs_$stem"
      if [[ -d "$d" && -f "$d/paths.txt" ]]; then
        run_batch "$d" "$stem"
      fi
    done
    if [[ "$INCLUDE_VZ" -eq 1 ]]; then
      d="$EXT/ffcs_vz"
      if [[ -d "$d" && -f "$d/paths.txt" ]]; then
        run_batch "$d" "vz (many blocks; large disk/time)" ${VZ_EXTRA[@]+"${VZ_EXTRA[@]}"}
      fi
    else
      echo "Skipped vz.wad batch (quick mode). Use full default without --quick, or add --decompress-vz."
    fi
    ;;
  full)
    for wad in "${WADS[@]}"; do
      stem="$(basename "$wad" .wad)"
      d="$EXT/ffcs_$stem"
      [[ -d "$d" && -f "$d/paths.txt" ]] || continue
      if [[ "$stem" == vz ]]; then
        run_batch "$d" "vz (many blocks)" ${VZ_EXTRA[@]+"${VZ_EXTRA[@]}"}
      else
        run_batch "$d" "$stem"
      fi
    done
    ;;
esac

if [[ "$DECOMPRESS_MODE" == "full" ]]; then
  echo "Verifying every .wad with FFCS has a non-empty batch_* output…"
  verify_full_batches
fi

if [[ "$NO_STAGE2" -eq 0 ]]; then
  echo "Stage 2 — UCFX / mesh / textures / Havok (parallel under $EXT)…"
  if [[ "${STAGE2_SEQUENTIAL:-0}" == "1" ]]; then
    "$STAGE2_SCRIPT" "$DEST" || die "stage 2 reported failures (see $EXT/review/)"
  else
    if [[ -n "${STAGE2_JOBS:-}" ]]; then
      "$STAGE2_PARALLEL_SCRIPT" "$DEST" "$STAGE2_JOBS" || die "stage 2 reported failures (see $EXT/review/)"
    else
      "$STAGE2_PARALLEL_SCRIPT" "$DEST" || die "stage 2 reported failures (see $EXT/review/)"
    fi
  fi
else
  echo "Skipping stage 2 (--no-stage2)."
fi

echo "Done. Root: $DEST"
echo "     Pipeline outputs: $EXT"
