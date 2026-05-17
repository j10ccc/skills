A personal collection of [Agent Skills](https://docs.claude.com/en/docs/claude-code/skills) — small, opinionated capability packs I've written for myself and left here in case they're useful to you too. Click into a skill's folder for details.

## Skills

| Skill | What it does |
| --- | --- |
| [github-star-recall](./skills/github-star-recall) | Rediscover and prune forgotten GitHub stars, one at a time. |
|| [j10c-frontend-playbook](./skills/j10c-frontend-playbook) | My personal React + TypeScript rules for AI agents writing code on my behalf. Includes fix-patterns/ — empirical weakness patterns from Taro/Vue projects with self-check lists and fix templates. |
| [soco-cli](./skills/soco-cli) | Sonos automation — alarms, sleep timers, scripted scenes. |

## Install

Interactive install — prompts you to pick which skills to add:

```bash
npx skills add j10ccc/skills
```

Install a specific skill non-interactively:

```bash
npx skills add j10ccc/skills -s j10c-frontend-playbook -y
```

## License

[MIT](LICENSE) © j10ccc
