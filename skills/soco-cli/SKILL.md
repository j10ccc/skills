---
name: soco-cli
description: Sonos speaker automation via the `soco` CLI (avantrec/soco-cli) — alarms, sleep timers, command chaining (wait/loop/if), local audio file playback, HTTP API server, interactive single-keystroke remote. This skill should be used when the user wants scripting/automation beyond simple play/pause, or asks about "alarm", "sleep timer", "play local file", "auto-stop after N minutes", "home automation HTTP", "broadcast across rooms", or similar Sonos automation scenarios.
allowed-tools: Bash Read
---

# soco-cli

Python-based Sonos CLI from `avantrec/soco-cli`. Its superpower vs other Sonos CLIs is the **command-chain DSL** (`:` separator + `wait`/`loop`/`if`), **native Alarm CRUD**, **local file playback** (auto-spawns a Range-capable HTTP server), and an **HTTP API server** for home automation.

All commands in this skill use `soco`. If `soco` is missing or behaves oddly, see [`references/atoms/troubleshooting.md`](references/atoms/troubleshooting.md).

## Quick smoke test

```sh
soco-discover                # populate ~/.soco-cli/ speaker cache (run once)
soco Kitchen status          # confirm the speaker is reachable
soco Kitchen vol 25          # change volume; exit 0 = success
```

## Before Implementation

Gather context before generating a command:

| Source | Gather |
|---|---|
| **Codebase / environment** | Existing cron lines, systemd units, HA configs, alias files, `~/.soco-cli/` cache state — anything the new command must coexist with |
| **Conversation** | The user's specific room name, favourite name, timing, automation goal, trust boundary (LAN vs internet) |
| **Skill References** | The right atom + scenario for the request — use the Quick lookup table below |
| **User Guidelines** | Project-specific conventions in `CLAUDE.md` (cron user, file paths, security defaults) |

For requests that touch existing speaker state, verify it live before generating the command:

| Request touches | Verify first |
|---|---|
| Existing alarm (modify/disable/delete) | `soco <speaker> alarms_spec` — see live IDs + spec |
| A favourite name | `soco <speaker> lf` — confirm exact spelling/case |
| A playlist name | `soco <speaker> lp` |
| Group membership | `soco groups` |
| Cron / HTTP / batch script | confirm `~/.soco-cli/` cache exists (run `soco-discover` if not), then pass `-l` |
| Any complex action | `soco --commands \| grep <action>` if action isn't in the cheat sheet |

For one-shot trivial actions (`play`, `pause`, `vol N`), skip the pre-flight — speed > rigor.

## Clarification triggers

### Required Clarifications (don't generate a command without these)

1. **Speaker name is ambiguous** (e.g., "the speaker upstairs", or a partial that matches multiple rooms) — ask for the exact room name or have the user pick from `soco speakers`.
2. **"play this file"** — confirm the codec is supported (see `references/atoms/local-file-playback.md`; soco-cli does not transcode) and that the controller machine has a NIC in the speaker's subnet.
3. **"automate via Home Assistant / curl / public endpoint"** — confirm the trust boundary: the HTTP API server has no auth, so deploying it must stay LAN-only or be fronted by nginx + auth.

### Optional Clarifications (defaults are safe; ask only if intent is unclear)

4. **"remind me at 7am" / "wake me up at X"** — default to a **native Sonos alarm** (lives on the speaker, survives controller offline; see `references/atoms/alarms.md`). Offer **cron + chain** (compose with `command-chaining.md`) if they need ramping, multi-room, or branching.
5. **"announce / broadcast"** — default to ungrouping back to the original layout after the announcement. Ask only if the user might prefer to leave the rooms grouped.

> Avoid asking too many questions in a single message. Skip Required Clarifications if the user has already named a specific room / file / endpoint elsewhere in the conversation.

## Quick lookup — which atom/scenario do I load?

| User says… | Load |
|---|---|
| "alarm", "every morning", "wake up" | `references/atoms/alarms.md` |
| "auto-stop", "after N minutes", "for half an hour" | `references/atoms/command-chaining.md` + `references/scenarios/bedtime-and-radio.md` |
| "Home Assistant", "curl", "HTTP", "API" | `references/atoms/http-api-server.md` + `references/scenarios/home-automation-http.md` |
| "play local file", "announcement", "doorbell" | `references/atoms/local-file-playback.md` + `references/scenarios/whole-house-broadcast.md` |
| "single key", "one button", "kitchen remote" | `references/atoms/interactive-shell.md` + `references/scenarios/kitchen-remote.md` |
| "auto-resume", "every hour", "Pomodoro", "cron" | `references/atoms/command-chaining.md` + `references/scenarios/watchdog-and-cron.md` |
| "discovery slow", "not found", "binary collision" | `references/atoms/troubleshooting.md` |
| "alarm spec", "8 fields", "modify_alarm" | `references/atoms/alarms.md` |
| "what's playing", "where's it from", "which service" | `references/atoms/sources-and-uris.md` (use `get_uri` then decode) |

---

## Essentials (inline — used in nearly every command)

### Speaker selection

```
soco <SPEAKER> <action> [args] [: <action> [args] ...]
```

- `<SPEAKER>` = room name (case-insensitive, **partial match** if unambiguous: `kit` → `Kitchen`), IPv4, or `_all_` (fan out to every visible speaker).
- `export SPKR="Kitchen"` lets you omit the name; `--no-env` ignores it for one call.
- **Always pass `-l`** in cron/scripts/HTTP server to use the cached speaker list — without it, every call does fresh SSDP discovery (~1s slower):

```sh
soco-discover        # populate cache once
soco -l Kitchen play
```

Full reference: [`references/atoms/speaker-selection.md`](references/atoms/speaker-selection.md) — multi-NIC `--subnet`, fuzzy match rules, refresh tactics.

### Command-chain DSL (the killer feature)

Separator is **space-colon-space** (`seek 12:34` is safe — no surrounding spaces). Each segment is `<action> [args]`; the speaker carries over but can be overridden per-segment.

**Durations**: `30s` / `5m` / `2h` / bare integer seconds / `HH:MM:SS`.

**Waits** (block on time or speaker events):

| Action | Returns when |
|---|---|
| `wait <dur>` / `wait_until <HH:MM>` | Time elapsed |
| `wait_start` / `wait_stop` | Transport state changes |
| `wait_stopped_for <dur>` / `wsf` | Stopped for ≥ dur (counts pauses) |
| `wait_end_track` | Current track completes |

**Loops**: `loop` (infinite) / `loop <N>` / `loop_for <dur>` / `loop_until <HH:MM>`. The loop marker re-anchors at the position where `loop` appears — actions before it run once.

**Guards** (silently abort the rest of the chain if false): `if_playing`, `if_stopped`, `if_coordinator`, `if_not_coordinator`, `if_queue`, `if_no_queue`.

```sh
# auto-stop after 30 min, only if not already playing
soco Kitchen if_stopped : play_fav "BBC R4" : wait 30m : stop

# Pomodoro
soco Office loop 5 : play_fav "Focus" : wait 30m : stop : wait 30m

# auto-resume on stop, all evening
soco Bathroom loop_until 22:00 : if_stopped : play : wait 10s
```

Full reference: [`references/atoms/command-chaining.md`](references/atoms/command-chaining.md) — every wait/loop variant and composition rules.

### Top-frequency actions

| Category | Common forms |
|---|---|
| Transport | `play` `pause` `stop` `next` `prev` `playpause` `seek HH:MM:SS` `transfer_to <speaker>` |
| Volume | `vol [N]` `rv ±N` `gv [N]` (group) `ramp_to_volume N` `mute on\|off` |
| Queue | `lq` (list) `pfq N` (play position) `cq` (clear) `auq <uri>` `sharelink <url>` `save_queue <name>` |
| Favourites | `lf` (list) `pf "<name>"` `pfn <N>` `afq "<name>"` (add to queue) |
| Grouping | `g <speaker>` (join) `ug` `ungroup_all` `party` `pair <right>` |
| Sleep | `sleep <dur\|off>` `sleep_at <HH:MM>` |
| Info | `info` `track` `status` `get_uri` `groups` `zones` |

Full reference: [`references/atoms/actions-cheatsheet.md`](references/atoms/actions-cheatsheet.md) — EQ, library search, surround, ~200 total actions with aliases. **List every action name with `soco --commands`** (top-level flag, pipe to grep).

> ⚠️ If a needed action isn't in the table above or in `references/atoms/actions-cheatsheet.md`, **don't invent it by analogy** — run `soco --commands | grep <keyword>` to confirm. Note: bare `actions` is a REPL-only command inside `soco --interactive`, **not** a top-level CLI subcommand. See `references/atoms/actions-cheatsheet.md` for unintuitive name examples.

## Quality gates

### Must follow

- [ ] Pass `-l` / `--use-local-speaker-list` in cron, scripts, and the HTTP API server — avoids per-call SSDP rescan.
- [ ] Use **space-colon-space** ` : ` for chains. `play:stop` is a single arg and won't split.
- [ ] Use `soco` as the command name throughout (verify install with `soco --version` → `soco-cli x.y.z`; skill examples target soco-cli ≥ 0.4.83 — if user's version is older and an action isn't recognized, confirm with `soco --commands | grep <action>`).
- [ ] Quote favourite names with spaces: `pf "BBC Radio 4"`, never `pf BBC Radio 4`.
- [ ] In alarm specs, match the favourite name exactly as it appears in the Sonos app (case + punctuation).

### Must avoid

- ❌ `play_file` against codecs soco-cli can't serve — it does **not** transcode (see `references/atoms/local-file-playback.md` for the supported list).
- ❌ `play_directory` expecting recursion — it scans one level only.
- ❌ Exposing the HTTP API server beyond the trusted LAN without auth / TLS in front.
- ❌ `add_alarm` with `recurrence=ONCE` for repeating alarms (self-disables after firing).
- ❌ Including seconds in alarm `start_time` / `duration` — both are `HH:MM` only (`07:00`, not `07:00:00`).

### Before recommending — output checklist

When you're about to give the user a `soco …` command, verify:

1. **Speaker name** is quoted if it contains spaces.
2. **`:` separators** have spaces on both sides.
3. **Favourite / playlist names** are quoted.
4. **Cron / script context** → `-l` is present.
5. **Local file recipe** → file format is in the supported list, and the controller machine's NIC reaches the speaker's subnet.
6. **HTTP API recipe** → user confirmed LAN-only deployment, or accepts an auth-less endpoint.

---

## Deeper atomic capabilities (`references/atoms/`)

Load when the task specifically needs the mechanic:

- [Alarms](references/atoms/alarms.md) — 8-field spec, recurrence bitmaps, `add_alarm`/`modify_alarm`/`alarms_spec`.
- [Local file playback](references/atoms/local-file-playback.md) — `play_file`/`play_directory`/`play_m3u`, Range HTTP server, supported formats, `_end_on_pause_`.
- [Sources & URI decoding](references/atoms/sources-and-uris.md) — interpreting `get_uri` output: URI schemes and `sid=N` → Spotify / Apple Music / Tidal / etc. Load when the user asks "what's playing" / "where's it from".
- [HTTP API server](references/atoms/http-api-server.md) — endpoints, JSON return shape, `macros.txt` syntax, `async_` semantics.
- [Interactive shell](references/atoms/interactive-shell.md) — REPL, alias subroutines, `push`/`pop`, single-keystroke mode.
- [Troubleshooting](references/atoms/troubleshooting.md) — binary collision, slow discovery, multi-NIC, macOS privacy, alarms not firing.

## Scenarios (`references/scenarios/`)

Real-life situations with copy-pasteable recipes:

- [Bedtime & timed radio](references/scenarios/bedtime-and-radio.md) — auto-stop after N min, stop after current track, sleep timer, fade-out.
- [Whole-house broadcasts](references/scenarios/whole-house-broadcast.md) — "dinner's ready" file broadcast, doorbell chime, party mode.
- [Home Assistant / curl-driven control](references/scenarios/home-automation-http.md) — HTTP server deployment, HA REST commands, presence-based switching.
- [One-key kitchen remote](references/scenarios/kitchen-remote.md) — single-keystroke shell, Raspberry Pi deployment.
- [Watchdog loops & cron schedules](references/scenarios/watchdog-and-cron.md) — auto-resume, hourly rotation, Pomodoro, quiet-hours cron.

## Official documentation

| Resource | URL | Use when |
|---|---|---|
| Upstream soco-cli README | https://github.com/avantrec/soco-cli | Latest action list, install / upgrade, CHANGELOG |
| `action_processor.py` | https://github.com/avantrec/soco-cli/blob/main/soco_cli/action_processor.py | Definitive action dictionary — verify names not in the cheat sheet |
| SoCo Python library | https://github.com/SoCo/SoCo | Underlying UPnP / SOAP issues, library-level bugs |
| Sonos UPnP service reference | https://sonos.svrooij.io/ | UPnP service / event names, raw SOAP debugging |
