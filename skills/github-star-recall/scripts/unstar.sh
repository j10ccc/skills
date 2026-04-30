#!/usr/bin/env bash
# unstar.sh <owner/repo> — remove the user's star from the given repo via gh.
# This calls DELETE /user/starred/{owner}/{repo} which is irreversible from the
# user's perspective (the star will silently disappear from their list and the
# repo's count drops by one). Only run after explicit user confirmation.

set -euo pipefail

if [[ $# -ne 1 || -z "$1" ]]; then
  echo "usage: unstar.sh <owner/repo>" >&2
  exit 2
fi

REPO="$1"

if ! [[ "$REPO" =~ ^[^/]+/[^/]+$ ]]; then
  echo "[github-star-recall] not a valid owner/repo: $REPO" >&2
  exit 2
fi

gh api -X DELETE "user/starred/$REPO" --silent
echo "[github-star-recall] unstarred: $REPO" >&2
