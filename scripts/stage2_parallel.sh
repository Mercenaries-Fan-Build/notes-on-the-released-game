#!/usr/bin/env bash
#
# Parallel stage 2 — same steps as stage2_review_extract.sh, one worker per blob (xargs -P).
#
# Usage:
#   ./scripts/stage2_parallel.sh /path/to/pipeline-root [jobs]
#
# jobs defaults to max(1, hw.ncpu - 4). Pass a second argument to override (e.g. 8).
#
# Env (same as stage2_review_extract.sh; PYTHON defaults to .venv if present):
#   PYTHON, MESH_FORMAT, TEXTURE_PNG, TEXTURE_INDEX, HAVOK_CONVEX_OBJ,
#   STAGE2_SKIP_UCFX, STAGE2_SKIP_MESH, STAGE2_SKIP_TEX, STAGE2_SKIP_HAVOK,
#   STAGE2_DIALOG, STAGE2_LEVEL, STAGE2_EMBEDDED_AUDIO, STAGE2_GLTF
#

set -uo pipefail

die() { echo "error: $*" >&2; exit 1; }

PIPELINE_ROOT="${1:?usage: $0 <pipeline-root> [jobs]}"
_ncpu="$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 8)"
if [[ -n "${2:-}" ]]; then
  JOBS="$2"
else
  if [[ "$_ncpu" -gt 4 ]]; then
    JOBS=$((_ncpu - 4))
  else
    JOBS=1
  fi
fi
[[ "$JOBS" -lt 1 ]] && JOBS=1
[[ -d "$PIPELINE_ROOT" ]] || die "not a directory: $PIPELINE_ROOT"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -z "${PYTHON:-}" ]]; then
  if [[ -x "$REPO_ROOT/.venv/bin/python" ]]; then
    PYTHON="$REPO_ROOT/.venv/bin/python"
  else
    PYTHON="python3"
  fi
fi
MESH_FORMAT="${MESH_FORMAT:-obj}"

UCFX="$REPO_ROOT/tools/ucfx_parser.py"
MESH="$REPO_ROOT/tools/mesh_extractor.py"
TEX="$REPO_ROOT/tools/texture_extractor.py"
HAV="$REPO_ROOT/tools/havok_extractor.py"
GLTF="$REPO_ROOT/tools/gltf_exporter.py"
DIALOG="$REPO_ROOT/tools/dialog_extractor.py"
LEVEL="$REPO_ROOT/tools/level_extractor.py"
PWS="$REPO_ROOT/tools/pws_extractor.py"

for t in "$UCFX" "$MESH" "$TEX" "$HAV" "$GLTF" "$DIALOG" "$LEVEL" "$PWS"; do
  [[ -f "$t" ]] || die "missing $t"
done

if [[ -d "$PIPELINE_ROOT/extracted" ]]; then
  REVIEW="$PIPELINE_ROOT/extracted/review"
else
  REVIEW="$PIPELINE_ROOT/review"
fi
mkdir -p "$REVIEW"

bins=()
shopt -s nullglob
for root in "$PIPELINE_ROOT/extracted" "$PIPELINE_ROOT"; do
  [[ -d "$root" ]] || continue
  for b in "$root"/batch_*/blocks/*.bin; do
    bins+=("$b")
  done
done
shopt -u nullglob

total=${#bins[@]}
RUN_ID="$(date +%Y%m%d-%H%M%S)"
LOG="$REVIEW/stage2_parallel_${RUN_ID}.log"
FAIL="$REVIEW/stage2_parallel_${RUN_ID}_failures.txt"
: >"$FAIL"
: >"$LOG"

echo "Stage 2 parallel → $REVIEW ($total blobs, $JOBS workers)"
echo "Log: $LOG"

if [[ "$total" -eq 0 ]]; then
  echo "No blobs under .../batch_*/blocks/*.bin — run stage 1 batch decompress first."
  exit 0
fi

process_one() {
  local binf="$1"
  local blocks_dir pack_dir pack stem out ec
  blocks_dir="$(dirname "$binf")"
  pack_dir="$(dirname "$blocks_dir")"
  pack="$(basename "$pack_dir")"
  stem="$(basename "$binf" .bin)"
  out="$REVIEW/$pack/$stem"
  mkdir -p "$out/textures" "$out/havok"
  ec=0

  {
    echo "======== $pack / $stem ========"
    if [[ "${STAGE2_SKIP_UCFX:-0}" != "1" ]]; then
      if "$PYTHON" "$UCFX" "$binf" --out "$out/ucfx.json"; then
        :; else echo "FAILED ucfx $binf" >>"$FAIL"; ec=1; fi
    fi

    if [[ "${STAGE2_SKIP_MESH:-0}" != "1" ]]; then
      mesh_out="$out/mesh.$MESH_FORMAT"
      MESHARGS=()
      TEX_IDX="${TEXTURE_INDEX:-}"
      [[ -n "$TEX_IDX" && -f "$TEX_IDX" ]] && MESHARGS+=(--texture-index "$TEX_IDX")
      if "$PYTHON" "$MESH" "$binf" --out "$mesh_out" --format "$MESH_FORMAT" --indices --stem "$stem" --per-submesh-obj "${MESHARGS[@]}"; then
        :; else echo "FAILED mesh $binf" >>"$FAIL"; ec=1; fi
    fi

    if [[ "${STAGE2_SKIP_TEX:-0}" != "1" ]]; then
      TEXARGS=()
      [[ "${TEXTURE_PNG:-1}" == "1" ]] && TEXARGS+=(--png)
      TEX_IDX="${TEXTURE_INDEX:-}"
      [[ -n "$TEX_IDX" && -f "$TEX_IDX" ]] && TEXARGS+=(--texture-index "$TEX_IDX")
      [[ -f "$out/shared_textures.json" ]] && TEXARGS+=(--shared-textures "$out/shared_textures.json")
      if "$PYTHON" "$TEX" "$binf" --out-dir "$out/textures" "${TEXARGS[@]}" --stem "$stem"; then
        :; else echo "FAILED textures $binf" >>"$FAIL"; ec=1; fi
    fi

    if [[ "${STAGE2_GLTF:-1}" == "1" ]] && [[ -f "$out/submeshes/index.json" ]]; then
      if "$PYTHON" "$GLTF" --review-dir "$out" --out "$out/mesh_scene.gltf" --stem "$stem"; then
        :; else echo "FAILED gltf $binf" >>"$FAIL"; ec=1; fi
    fi

    HAVARGS=()
    [[ "${HAVOK_CONVEX_OBJ:-1}" == "1" ]] && HAVARGS+=(--emit-convex-obj)
    if [[ "${STAGE2_SKIP_HAVOK:-0}" != "1" ]]; then
      if "$PYTHON" "$HAV" "$binf" --out-dir "$out/havok" "${HAVARGS[@]}"; then
        :; else echo "FAILED havok $binf" >>"$FAIL"; ec=1; fi
    fi

    if [[ "${STAGE2_DIALOG:-1}" != "0" ]]; then
      if "$PYTHON" "$DIALOG" "$binf" --out "$out/dialog_fragments.json"; then
        :; else echo "FAILED dialog $binf" >>"$FAIL"; ec=1; fi
    fi

    if [[ "${STAGE2_LEVEL:-0}" == "1" ]]; then
      if "$PYTHON" "$LEVEL" --blob "$binf" --out "$out/level_hints.json"; then
        :; else echo "FAILED level $binf" >>"$FAIL"; ec=1; fi
    fi

    if [[ "${STAGE2_EMBEDDED_AUDIO:-0}" == "1" ]]; then
      mkdir -p "$out/audio_embedded"
      if "$PYTHON" "$PWS" "$binf" --out-dir "$out/audio_embedded"; then
        :; else echo "FAILED embedded_audio $binf" >>"$FAIL"; ec=1; fi
    fi
  } >>"$LOG" 2>&1

  return "$ec"
}

export -f process_one
export PYTHON MESH_FORMAT UCFX MESH TEX HAV GLTF DIALOG LEVEL PWS
export REVIEW FAIL LOG
export STAGE2_SKIP_UCFX="${STAGE2_SKIP_UCFX:-0}"
export STAGE2_SKIP_MESH="${STAGE2_SKIP_MESH:-0}"
export STAGE2_SKIP_TEX="${STAGE2_SKIP_TEX:-0}"
export STAGE2_SKIP_HAVOK="${STAGE2_SKIP_HAVOK:-0}"
export TEXTURE_PNG="${TEXTURE_PNG:-1}"
export TEXTURE_INDEX="${TEXTURE_INDEX:-}"
export HAVOK_CONVEX_OBJ="${HAVOK_CONVEX_OBJ:-1}"
export STAGE2_DIALOG="${STAGE2_DIALOG:-1}"
export STAGE2_LEVEL="${STAGE2_LEVEL:-0}"
export STAGE2_EMBEDDED_AUDIO="${STAGE2_EMBEDDED_AUDIO:-0}"
export STAGE2_GLTF="${STAGE2_GLTF:-1}"

printf '%s\n' "${bins[@]}" | xargs -P "$JOBS" -I {} bash -c 'process_one "$@"' _ {}

INDEX="$REVIEW/stage2_parallel_index_${RUN_ID}.txt"
{
  echo "run_id $RUN_ID"
  echo "pipeline_root $PIPELINE_ROOT"
  echo "total_blobs $total"
  echo "jobs $JOBS"
  echo "log $LOG"
  [[ -s "$FAIL" ]] && echo "failures_file $FAIL"
} | tee "$INDEX"

echo "Stage 2 parallel done (see $LOG)"
if [[ -s "$FAIL" ]]; then
  echo "Some steps failed — see $FAIL" >&2
  exit 1
fi
