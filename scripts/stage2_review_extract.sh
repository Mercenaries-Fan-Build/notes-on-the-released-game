#!/usr/bin/env bash
#
# Stage 2 — full review pass on every decompressed .block blob:
#   ucfx_parser → mesh_extractor → texture_extractor → havok_extractor
#   dialog_extractor (optional) → level_extractor (optional)
#
# Expects decompressed blocks from stage 1 under either or both:
#   <pipeline-root>/extracted/batch_*/blocks/*.bin   (extract_from_zip layout)
#   <pipeline-root>/batch_*/blocks/*.bin             (legacy repo output/)
#
# Writes per-blob review trees:
#   <pipeline-root>/extracted/review/<batch_pack>/<stem>/   if extracted/ exists
#   <pipeline-root>/review/<batch_pack>/<stem>/             otherwise (legacy layout)
#     ucfx.json   textures/  havok/  mesh.obj  mesh.meta.json
#     dialog_fragments.json  level_hints.json (when enabled)
#
# Usage:
#   ./scripts/stage2_review_extract.sh /path/to/output
#
# Env:
#   PYTHON              interpreter (default: repo .venv/bin/python if present, else python3)
#   MESH_FORMAT         obj | gltf  (default: obj)
#   STAGE2_SKIP_UCFX    1 to skip ucfx JSON
#   STAGE2_SKIP_MESH    1 to skip mesh
#   STAGE2_SKIP_TEX     1 to skip textures
#   STAGE2_SKIP_HAVOK   1 to skip havok slices
#   TEXTURE_PNG         1 (default) pass --png to texture_extractor (needs ffmpeg for PNG)
#   TEXTURE_INDEX       path to texture_index.json for cross-block mip assembly (Makefile sets this for review-all)
#   STAGE2_DIALOG       1 (default) run dialog_extractor per blob
#   STAGE2_LEVEL        0 (default) run level_extractor per blob (adds JSON hints)
#   HAVOK_CONVEX_OBJ    1 (default) pass --emit-convex-obj to havok_extractor
#   STAGE2_EMBEDDED_AUDIO 0 (default) run pws_extractor on each blob for RIFF/Ogg slices (slow)
#   STAGE2_GLTF         1 (default) emit mesh_scene.gltf (+ .bin) after mesh/textures; 0 to skip (needs pygltflib)
#   STAGE2_ANIM         0 (default) set to 1 to run mercs2_anim_pipeline.py after all blobs → <pipeline-root>/animations
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
MESH_FORMAT="${MESH_FORMAT:-obj}"

UCFX="$REPO_ROOT/tools/ucfx_parser.py"
MESH="$REPO_ROOT/tools/mesh_extractor.py"
TEX="$REPO_ROOT/tools/texture_extractor.py"
HAV="$REPO_ROOT/tools/havok_extractor.py"
GLTF="$REPO_ROOT/tools/gltf_exporter.py"
DIALOG="$REPO_ROOT/tools/dialog_extractor.py"
LEVEL="$REPO_ROOT/tools/level_extractor.py"
PWS="$REPO_ROOT/tools/pws_extractor.py"
ANIM="$REPO_ROOT/tools/mercs2_anim_pipeline.py"

for t in "$UCFX" "$MESH" "$TEX" "$HAV" "$GLTF" "$DIALOG" "$LEVEL" "$PWS" "$ANIM"; do
  [[ -f "$t" ]] || die "missing $t"
done

PIPELINE_ROOT="${1:?usage: $0 <pipeline-root> (folder containing extracted/ or batch_*/)}"
[[ -d "$PIPELINE_ROOT" ]] || die "not a directory: $PIPELINE_ROOT"

bins=()
shopt -s nullglob
for root in "$PIPELINE_ROOT/extracted" "$PIPELINE_ROOT"; do
  [[ -d "$root" ]] || continue
  for b in "$root"/batch_*/blocks/*.bin; do
    bins+=( "$b" )
  done
done
shopt -u nullglob

if [[ -d "$PIPELINE_ROOT/extracted" ]]; then
  REVIEW="$PIPELINE_ROOT/extracted/review"
else
  REVIEW="$PIPELINE_ROOT/review"
fi

mkdir -p "$REVIEW"

RUN_ID="$(date +%Y%m%d-%H%M%S)"
LOG="$REVIEW/stage2_${RUN_ID}.log"
FAIL="$REVIEW/stage2_${RUN_ID}_failures.txt"
: >"$FAIL"

echo "Stage 2 review extract → $REVIEW"
echo "Logging to $LOG"

if [[ ${#bins[@]} -eq 0 ]]; then
  echo "No blobs under .../batch_*/blocks/*.bin — run stage 1 batch decompress first." | tee -a "$LOG"
  exit 0
fi

total=${#bins[@]}
n=0
ok=0
fail=0

run_step() {
  local step="$1"
  shift
  if "$@"; then
    return 0
  fi
  echo "FAILED $step $binf" >>"$FAIL"
  return 1
}

for binf in "${bins[@]}"; do
  n=$((n + 1))
  blocks_dir="$(dirname "$binf")"
  pack_dir="$(dirname "$blocks_dir")"
  pack="$(basename "$pack_dir")"
  stem="$(basename "$binf" .bin)"
  out="$REVIEW/$pack/$stem"
  mkdir -p "$out/textures" "$out/havok"

  echo "[$n/$total] $pack / $stem" | tee -a "$LOG"

  ec=0
  if [[ "${STAGE2_SKIP_UCFX:-0}" != "1" ]]; then
    run_step ucfx "$PYTHON" "$UCFX" "$binf" --out "$out/ucfx.json" >>"$LOG" 2>&1 || ec=1
  fi

  if [[ "${STAGE2_SKIP_MESH:-0}" != "1" ]]; then
    mesh_out="$out/mesh.$MESH_FORMAT"
    MESHARGS=()
    TEX_IDX="${TEXTURE_INDEX:-}"
    [[ -n "$TEX_IDX" && -f "$TEX_IDX" ]] && MESHARGS+=(--texture-index "$TEX_IDX")
    run_step mesh "$PYTHON" "$MESH" "$binf" --out "$mesh_out" --format "$MESH_FORMAT" --indices --stem "$stem" --per-submesh-obj "${MESHARGS[@]}" >>"$LOG" 2>&1 || ec=1
  fi

  if [[ "${STAGE2_SKIP_TEX:-0}" != "1" ]]; then
    TEXARGS=()
    [[ "${TEXTURE_PNG:-1}" == "1" ]] && TEXARGS+=(--png)
    TEX_IDX="${TEXTURE_INDEX:-}"
    [[ -n "$TEX_IDX" && -f "$TEX_IDX" ]] && TEXARGS+=(--texture-index "$TEX_IDX")
    [[ -f "$out/shared_textures.json" ]] && TEXARGS+=(--shared-textures "$out/shared_textures.json")
    run_step textures "$PYTHON" "$TEX" "$binf" --out-dir "$out/textures" "${TEXARGS[@]}" --stem "$stem" >>"$LOG" 2>&1 || ec=1
  fi

  if [[ "${STAGE2_GLTF:-1}" == "1" ]] && [[ -f "$out/submeshes/index.json" ]]; then
    run_step gltf "$PYTHON" "$GLTF" --review-dir "$out" --out "$out/mesh_scene.gltf" --stem "$stem" >>"$LOG" 2>&1 || ec=1
  fi

  HAVARGS=()
  [[ "${HAVOK_CONVEX_OBJ:-1}" == "1" ]] && HAVARGS+=(--emit-convex-obj)
  if [[ "${STAGE2_SKIP_HAVOK:-0}" != "1" ]]; then
    run_step havok "$PYTHON" "$HAV" "$binf" --out-dir "$out/havok" "${HAVARGS[@]}" >>"$LOG" 2>&1 || ec=1
  fi

  if [[ "${STAGE2_DIALOG:-1}" != "0" ]]; then
    run_step dialog "$PYTHON" "$DIALOG" "$binf" --out "$out/dialog_fragments.json" >>"$LOG" 2>&1 || ec=1
  fi

  if [[ "${STAGE2_LEVEL:-0}" == "1" ]]; then
    run_step level "$PYTHON" "$LEVEL" --blob "$binf" --out "$out/level_hints.json" >>"$LOG" 2>&1 || ec=1
  fi

  if [[ "${STAGE2_EMBEDDED_AUDIO:-0}" == "1" ]]; then
    mkdir -p "$out/audio_embedded"
    run_step embedded_audio "$PYTHON" "$PWS" "$binf" --out-dir "$out/audio_embedded" >>"$LOG" 2>&1 || ec=1
  fi

  if [[ "$ec" -eq 0 ]]; then
    ok=$((ok + 1))
  else
    fail=$((fail + 1))
  fi
done

if [[ "${STAGE2_ANIM:-0}" == "1" ]]; then
  echo "STAGE2_ANIM=1 → mercs2_anim_pipeline.py --pipeline-root $PIPELINE_ROOT" | tee -a "$LOG"
  "$PYTHON" "$ANIM" --pipeline-root "$PIPELINE_ROOT" --filter all >>"$LOG" 2>&1 || {
    echo "warning: mercs2_anim_pipeline failed (see $LOG)" >&2
  }
fi

INDEX="$REVIEW/stage2_index_${RUN_ID}.txt"
{
  echo "run_id $RUN_ID"
  echo "pipeline_root $PIPELINE_ROOT"
  echo "total_blobs $total"
  echo "ok $ok"
  echo "fail $fail"
  echo "log $LOG"
  [[ -s "$FAIL" ]] && echo "failures_file $FAIL"
} | tee "$INDEX"

echo "Stage 2 done. OK=$ok FAIL=$fail (see $LOG)"
if [[ -s "$FAIL" ]]; then
  echo "Some steps failed — see $FAIL" >&2
  exit 1
fi
