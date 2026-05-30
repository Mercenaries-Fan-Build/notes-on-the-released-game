#!/usr/bin/env bash
#
# Post-stage-2 validation (Rust UCFX + optional glTF). Invoked when STAGE2_VALIDATE_RUST=1
# or manually: ./scripts/stage2_post_validate.sh /path/to/output
#
# Env:
#   STAGE2_VALIDATE_RUST=1      Run ucfx_byteswap --validate-only on decompressed blobs
#   STAGE2_VALIDATE_GLTF=1      Run gltf_validate.py on review dirs with mesh_scene.gltf
#   STAGE2_VALIDATE_SAMPLE=N    Cap blob count (0 = all)
#   STAGE2_VALIDATE_JOBS=N      Parallel Rust workers (default 8)
#   STAGE2_VALIDATE_STRICT=1    Non-zero exit on any Rust issue
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PIPELINE_ROOT="${1:?usage: $0 <pipeline-root>}"

if [[ -z "${PYTHON:-}" ]]; then
  if [[ -x "$REPO_ROOT/.venv/bin/python" ]]; then
    PYTHON="$REPO_ROOT/.venv/bin/python"
  elif [[ -x "$REPO_ROOT/.venv/Scripts/python.exe" ]]; then
    PYTHON="$REPO_ROOT/.venv/Scripts/python.exe"
  else
    PYTHON="python3"
  fi
fi

ARGS=()
[[ "${STAGE2_VALIDATE_RUST:-0}" == "1" ]] && ARGS+=(--rust)
[[ "${STAGE2_VALIDATE_GLTF:-0}" == "1" ]] && ARGS+=(--gltf)
[[ -z "${ARGS[*]:-}" ]] && ARGS=(--rust)

SAMPLE="${STAGE2_VALIDATE_SAMPLE:-0}"
JOBS="${STAGE2_VALIDATE_JOBS:-8}"
[[ "$SAMPLE" != "0" ]] && ARGS+=(--sample "$SAMPLE")
ARGS+=(--jobs "$JOBS")
[[ "${STAGE2_VALIDATE_STRICT:-0}" == "1" ]] && ARGS+=(--strict)

exec "$PYTHON" "$REPO_ROOT/tools/stage2_post_validate.py" "$PIPELINE_ROOT" "${ARGS[@]}"
