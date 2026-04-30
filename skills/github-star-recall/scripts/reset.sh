#!/usr/bin/env bash
# reset.sh — clear recommendation history so pick.sh starts from scratch.
# Does NOT touch the cached star list (that ages out on its own 24h TTL).

set -euo pipefail

DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/github-star-recall"
HISTORY_FILE="$DATA_DIR/history.txt"

if [[ -f "$HISTORY_FILE" ]]; then
  COUNT=$(grep -c . "$HISTORY_FILE" || true)
  : > "$HISTORY_FILE"
  echo "[github-star-recall] cleared history ($COUNT entries)" >&2
else
  echo "[github-star-recall] no history to clear" >&2
fi
