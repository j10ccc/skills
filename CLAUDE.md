# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A personal collection of Anthropic Agent Skills consumed by Claude Code at runtime. Each subfolder under `skills/` is one self-contained skill. **There is no build, test, lint, or CI pipeline** — content is markdown plus the occasional shell script. Do not go looking for a `package.json`.

Distribution is via the third-party `vercel-labs/skills` CLI: `npx skills add j10ccc/skills` (interactive picker) or `npx skills add j10ccc/skills -s <skill-name> -y` (non-interactive single skill).

## Creating a new skill

Use the `skill-creator` skill — don't hand-roll the folder structure. It handles scaffolding, frontmatter, and the conventions for `scripts/` / `references/`.

## Conventions

- **One job per skill.** If the description has an "and", it's two skills.
- **Confirm before destructive actions.** Skills that unstar, delete, or otherwise change user-visible state must require explicit user confirmation before invoking the script. Do not read hesitation as consent.
- **Keep the README skills table in sync.** When adding, removing, or renaming a skill — or when its one-line purpose changes meaningfully — update the `## Skills` table in `README.md` in the same commit. The table is the human-facing index of this repo; treat it as part of the skill's surface area, not as decoration.
- **Validate before committing.** After modifying a skill, run the `skill-validator` skill against the changed skill(s) before staging the commit. It's a skill too — invoke it the same way you'd invoke any other.
- **Commit messages** follow conventional-commits with the skill name as scope:
  - `feat(soco-cli): ...`, `fix(github-star-recall): ...`, `refactor(j10c-frontend-playbook): ...`
  - Repo-wide changes use no scope: `docs: ...`, `chore: ...`
