#!/usr/bin/env bash
# pick.sh — pick a random starred repo not yet recommended.
# Output: single-line JSON on stdout.
#   On success: { full_name, description, language, html_url, topics,
#                 stargazers_count, updated_at, starred_at }
#   When the history is exhausted: { "error": "all_recommended", ... }
# Diagnostics go to stderr.

set -euo pipefail

DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/github-star-recall"
CACHE_FILE="$DATA_DIR/stars.json"
HISTORY_FILE="$DATA_DIR/history.txt"
CACHE_TTL_MIN=$((24 * 60))

mkdir -p "$DATA_DIR"
touch "$HISTORY_FILE"

needs_refresh() {
  [[ ! -s "$CACHE_FILE" ]] && return 0
  [[ -n $(find "$CACHE_FILE" -mmin "+$CACHE_TTL_MIN" 2>/dev/null) ]] && return 0
  return 1
}

if needs_refresh; then
  echo "[github-star-recall] refreshing star cache (this can take ~10s for 500+ repos)..." >&2
  # /user/starred with the v3 star+json accept header gives us starred_at alongside the repo.
  gh api --paginate \
    -H "Accept: application/vnd.github.star+json" \
    user/starred \
    --jq '.[] | {
      full_name: .repo.full_name,
      description: (.repo.description // ""),
      language: (.repo.language // ""),
      html_url: .repo.html_url,
      topics: (.repo.topics // []),
      stargazers_count: .repo.stargazers_count,
      updated_at: .repo.updated_at,
      starred_at: .starred_at
    }' \
    | jq -s '.' > "$CACHE_FILE.tmp"
  mv "$CACHE_FILE.tmp" "$CACHE_FILE"
fi

TOTAL=$(jq 'length' "$CACHE_FILE")
SEEN=$(grep -c . "$HISTORY_FILE" || true)
REMAINING=$(( TOTAL - SEEN ))

if (( REMAINING <= 0 )); then
  jq -n --argjson total "$TOTAL" --arg history "$HISTORY_FILE" '{
    error: "all_recommended",
    message: "All \($total) starred repos have been recommended at least once.",
    history_file: $history,
    hint: "Run scripts/reset.sh to start over."
  }'
  exit 0
fi

# Random pick from repos whose full_name is not in history.
# $RANDOM is 0..32767 — fine for selecting from <50k items.
jq -c \
  --rawfile hist "$HISTORY_FILE" \
  --argjson r "$RANDOM" '
  ($hist | split("\n") | map(select(length > 0))) as $history
  | map(select(.full_name as $n | ($history | index($n)) | not))
  | .[$r % length]
' "$CACHE_FILE"
