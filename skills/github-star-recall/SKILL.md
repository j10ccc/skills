---
name: github-star-recall
description: Pick a random forgotten GitHub starred repo and offer to unstar it. Use when the user wants to rediscover or clean up their stars, including daily "star recall" digests from scheduled agents.
---

# GitHub Star Recall

Help the user revisit repos buried in their GitHub stars. Each invocation surfaces one repo they haven't seen before so they can decide: keep it, or unstar and move on.

## Flow

### 1. Pick a repo

Run `scripts/pick.sh`. It prints a single JSON object on stdout with these fields:

- `full_name` — e.g. `vercel/next.js`
- `description` — may be empty
- `language` — primary language, may be empty
- `html_url` — link to the repo
- `topics` — array of tags
- `stargazers_count` — the repo's total star count
- `updated_at` — ISO8601 of last repo activity
- `starred_at` — ISO8601 of when the user first starred it

If the output is `{"error": "all_recommended", ...}`, every starred repo has been shown at least once. Tell the user to run `scripts/reset.sh` (path is in the error payload) to start a fresh round.

The first run pulls the full starred list via `gh api user/starred` and caches it (~10s for 500+ repos). Subsequent runs within 24h use the cache.

### 2. Present the repo

Tell the user about the repo as flowing prose — the way you'd naturally bring it up in conversation, not as a spec sheet. Do **not** use a Markdown table or a bullet-list of metadata fields; weave the facts into one or two short paragraphs so the recall framing ("you starred this once, do you remember why?") feels like a story, not a form.

Use the user's natural conversation language, not the language this SKILL.md happens to be written in. If it isn't obvious from the request, match the language the user has been using in recent turns. For this user that defaults to Chinese — only switch to English if they're clearly speaking English to you.

Work the following details into the prose, in whatever order reads best:

- The repo name, as a clickable link to `html_url`
- Its description, if any
- The primary language, if any
- The current star count
- How long ago the user starred it — humanize `starred_at` (e.g. "two years ago")
- Whether the repo is still active — humanize `updated_at`. If it's been quiet for years, surface that explicitly; it's a strong "probably safe to unstar" signal.
- The topics, if any feel relevant

Close with a soft, conversational prompt: do they remember it, want to keep it, or want to unstar it. Don't pressure — the goal is rediscovery, not a forced cleanup.

### 3. Mark as shown

Immediately after presenting, run `scripts/mark.sh <full_name>` to append the repo to the history file. Do this *before* waiting for the user's reply, so the repo isn't recommended again even if the session ends here.

### 4. Handle the response

- **User wants to unstar** ("unstar", "delete it", "drop it", "trash", "扔了", "没用了", "删掉", etc.) — run `scripts/unstar.sh <full_name>` and confirm.
- **User wants to keep it** ("keep", "still useful", "留着") — do nothing further; the history mark from step 3 already prevents a repeat.
- **User wants another** ("next", "再来一个") — go back to step 1.
- **User wants more context** — fetch the README with `gh repo view <full_name>` and summarize.

Unstarring changes a public-facing GitHub signal (the repo's star count drops, the user's stars list shrinks). Always require an explicit confirmation. Don't read "I don't remember it" or "hmm, doubt I need it" as consent — ask.

## Design notes

- **Pick and mark are separate**: `pick.sh` is read-only, and you call `mark.sh` explicitly after presenting. This keeps debugging clean (you can peek without polluting history) and avoids silently losing a record if the script crashes mid-way.
- **The cache is 24h, deliberately**: pulling 500+ repos every invocation is slow, and a day-old cache fits the "dust off something forgotten" framing — repos the user starred this morning shouldn't show up tonight as "forgotten".
- **History is plain text, one `owner/repo` per line**: greppable, hand-editable, no locking, no SQLite. The user can clear or surgically edit it without learning anything.
- **`starred_at` matters more than `updated_at`** for recall. The most evocative question is "why did past-me star this two years ago?" — the original star date is the key memory hook.

## Data locations

- Cache: `~/.local/share/github-star-recall/stars.json` (24h TTL)
- History: `~/.local/share/github-star-recall/history.txt` (one `owner/repo` per line)

## Pairing with a scheduler

If the user wants a daily "star recall" delivered each morning, they should set that up with `/schedule` (or whatever cron-style agent runner they use) — this skill handles the single-shot recommendation, scheduling is a separate concern.
