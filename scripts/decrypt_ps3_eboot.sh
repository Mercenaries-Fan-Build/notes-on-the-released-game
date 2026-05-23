#!/usr/bin/env bash
# Decrypt PS3 EBOOT.BIN (SCE SELF) to ELF for static analysis.
#
# Prerequisites:
#   - oscetool built (or scetool) with PS3 keys in ./data/
#   - Do NOT set PS3= to a directory with wrong/custom keys (use repo script defaults)
#
# Usage:
#   ./scripts/decrypt_ps3_eboot.sh
#   ./scripts/decrypt_ps3_eboot.sh "game-files/[BLUS30056] Mercenaries 2 - World in Flames/PS3_GAME/USRDIR/EBOOT.BIN"

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EBOOT_IN="${1:-$REPO_ROOT/game-files/[BLUS30056] Mercenaries 2 - World in Flames/PS3_GAME/USRDIR/EBOOT.BIN}"
OUT_DIR="$REPO_ROOT/analysis/cross_platform/ps3_eboot"
OUT_ELF="$OUT_DIR/EBOOT.elf"
OSCETool_DIR="${OSCETOOL_DIR:-/tmp/oscetool}"
DATA_DIR="${PS3_KEYS_DATA:-$OSCETool_DIR/data}"

if [[ ! -f "$EBOOT_IN" ]]; then
  echo "error: EBOOT not found: $EBOOT_IN" >&2
  exit 1
fi

if [[ ! -x "$OSCETool_DIR/oscetool" ]]; then
  echo "Building oscetool in $OSCETool_DIR ..."
  if [[ ! -d "$OSCETool_DIR" ]]; then
    git clone --depth 1 https://github.com/spacemanspiff/oscetool.git "$OSCETool_DIR"
  fi
  make -C "$OSCETool_DIR"
fi

if [[ ! -f "$DATA_DIR/keys" || ! -f "$DATA_DIR/ldr_curves" || ! -f "$DATA_DIR/vsh_curves" ]]; then
  echo "error: missing keys in $DATA_DIR" >&2
  echo "  Clone https://github.com/jevinskie/ps3dotdir and copy data/:" >&2
  echo "    cp -r /path/to/ps3dotdir/data $DATA_DIR" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
# Unset PS3 env if it points at stale key dirs (common cause of decrypt failure)
env -u PS3 "$OSCETool_DIR/oscetool" -v -d "$EBOOT_IN" "$OUT_ELF" 2>&1 | tail -20
file "$OUT_ELF"
echo "Wrote $OUT_ELF"
