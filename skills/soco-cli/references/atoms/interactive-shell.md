# Interactive shell

Launched by running `soco` with no action (or just a speaker name). Drops into a REPL with an active-speaker concept, tab completion, persistent history, and alias subroutines.

## Entering / exiting

```sh
soco                  # REPL with no active speaker
soco Kitchen          # REPL with Kitchen pre-selected
soco --sk Kitchen     # REPL starting in single-keystroke mode
```

Prompt:
```
Sonos [Kitchen] >
```

Exit with `exit`, `quit`, or Ctrl-D.

## Shell-only commands (not in the action catalog)

| Command | Purpose |
|---|---|
| `set <speaker>` / `0` | Set / unset active speaker |
| `<N>` (number) | Select speaker by index from `speakers` |
| `speakers` | List cached speakers with indices |
| `actions` | List all action names |
| `rescan` / `rescan_max` | Refresh speaker cache (rescan_max = wider net) |
| `push` / `pop` | Save / restore active speaker (stack) |
| `cd <dir>` | Change shell cwd (for relative paths in `play_file`) |
| `exec <cmd>` | Run an OS shell command |
| `alias` / `aliases` / `save_aliases` / `load_aliases` | Manage aliases |
| `sk` / `single-keystroke` | Enter single-keystroke mode |
| `version`, `docs`, `help`, `check-for-update` | Self-explanatory |

Tab completion covers actions + speakers + alias names. Readline history persists at `~/.soco-cli/`.

## Alias subroutines

Aliases are first-class subroutines stored in `~/.soco-cli/aliases.pickle`. Define inline:

```
alias morning Kitchen vol 20 : play_fav "%1" : wait 30m : stop
alias quiet vol 10
alias bedtime quiet : sleep 30m       # aliases can call other aliases
```

Call:
```
morning "BBC R4"
bedtime
```

Persist:
```
save_aliases
```

(Aliases save automatically on `exit`; `save_aliases` is for paranoia or mid-session checkpointing.)

### Argument substitution

`%1` … `%9` interpolate positional args at call time:

```
alias r play_fav "%1" : wait %2 : stop
r "Jazz24" 45m
```

Missing args expand to empty string — defensive: surround in quotes (`"%1"`) so partially-substituted commands still parse.

### Recursion / cycle detection

`alias a b : c` and `alias c a` won't infinite-loop — soco-cli detects cycles and aborts the expansion with an error.

## `push` / `pop` speaker stack

Useful inside aliases that operate on multiple speakers but want to restore the caller's context:

```
alias announce push : set Kitchen : play_file /srv/dinner.mp3 : pop
```

The stack is unbounded; mismatched `pop` (empty stack) is a no-op.

## Single-keystroke mode

```
sk
```

Each typed character immediately invokes the matching alias — no Enter. Designed for one-key remotes. Define zero-arg aliases mapped to single-character names:

```
alias p play
alias s stop
alias + rv 5
alias - rv -5
alias 1 play_fav "BBC R4"
alias 2 play_fav "Jazz24"
sk
```

Now `p` plays, `+` raises volume, `1` switches station. Press Esc (or whatever the entry prompt indicated) to exit SK mode.

Limitation: SK aliases can't take arguments (no way to type them). For parameterized actions, use the regular REPL or HTTP macros.

## Long-running action forking

The shell runs these actions in a `soco` subprocess so Ctrl-C aborts them without killing the REPL:

- `track_follow` / `tf` / `tfc`
- `wait_*` actions
- `play_file`, `play_m3u`, `play_directory`
- `if_*` guards

Other actions run in-process.

## When to prefer interactive shell vs HTTP API

| Use case | Better choice |
|---|---|
| Personal one-key remote on your own machine | Interactive shell + `sk` |
| Physical button hardware | HTTP API + macros |
| Cross-device automation (HA, Node-RED) | HTTP API |
| Quick exploratory commands | Interactive shell |
| Scripted batch jobs | `soco` from shell with `:` chains |
