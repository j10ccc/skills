#!/usr/bin/env bash
# mark.sh <owner/repo> — append a repo to the recommended-history file
# so it won't be picked again by pick.sh.

set -euo pipefail

if [[ $# -ne 1 || -z "$1" ]]; then
  echo "usage: mark.sh <owner/repo>" >&2
  exit 2
fi

DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/github-star-recall"
HISTORY_FILE="$DATA_DIR/history.txt"
mkdir -p "$DATA_DIR"
touch "$HISTORY_FILE"

# Avoid duplicate lines if called twice for the same repo.
if grep -Fxq "$1" "$HISTORY_FILE"; then
  echo "[github-star-recall] already in history: $1" >&2
else
  echo "$1" >> "$HISTORY_FILE"
  echo "[github-star-recall] marked: $1" >&2
fi
