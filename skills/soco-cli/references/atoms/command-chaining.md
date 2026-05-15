# Command-chain DSL

soco-cli's killer feature: a single `soco` invocation can run an arbitrary sequence of actions with waits, loops, and conditionals.

## Separator

` : ` — **space, colon, space**. The whitespace matters: `seek 12:34` and `sleep_at 22:30` are unaffected because no spaces flank their colons.

```sh
soco Kitchen play_fav "BBC R4" : wait 30m : stop
```

Each segment is `<action> [args]`. The first segment uses the leading speaker; subsequent segments inherit the same speaker unless explicitly overridden (some segments are speaker-independent; see below).

## Speaker-independent segments

These don't take a speaker — they're chain primitives:

- `wait <dur>` / `wait_for <dur>` — pure timer.
- `wait_until <HH:MM>` — until clock time.
- `loop`, `loop <N>`, `loop_for <dur>`, `loop_until <HH:MM>`, `loop_to_start` — jump back to start.

Everything else needs a speaker. Re-specify mid-chain to switch:

```sh
soco Kitchen play : wait 10m : Lounge play
```

## Duration syntax

- `30s`, `5m`, `2h` — suffix forms.
- Bare integer = seconds.
- `HH:MM:SS` — also accepted for `sleep`.
- For alarm specs: `HH:MM:SS` only.

## Waits — block on speaker events

| Action | Returns when |
|---|---|
| `wait <dur>` / `wait_for` | Time elapsed |
| `wait_until <HH:MM>` | Clock hits time |
| `wait_start` | Speaker transitions to PLAYING |
| `wait_stop` | Speaker transitions to STOPPED **or** PAUSED |
| `wait_stop_not_pause` / `wsnp` | Speaker transitions to STOPPED (ignores pause) |
| `wait_stopped_for <dur>` / `wsf` | Has been stopped continuously for ≥ dur (counts pauses) |
| `wait_stopped_for_not_pause <dur>` / `wsfnp` | Has been stopped (not paused) for ≥ dur |
| `wait_end_track` | Current track completes |

`wait_start` / `wait_stop` use UPnP event subscriptions — they're cheap and react in milliseconds.

## Loops

```
loop                      # infinite
loop 5                    # 5 iterations
loop_for 1h               # repeat until 1h elapsed
loop_until 22:00          # repeat until clock time
loop_to_start             # rewind to start (vs. last loop marker)
```

The loop marker re-anchors at the position where `loop` appears. Things before `loop` run once; things after repeat:

```sh
soco Kitchen vol 20 : loop_until 22:00 : play_fav "Jazz" : wait 1h : next
```

`vol 20` runs once at start; the loop body is `play_fav … : wait 1h : next`.

## Conditional guards

These skip the rest of the chain if the condition is false. They don't fail — chain quietly exits with code 0.

- `if_playing` — current speaker is PLAYING.
- `if_stopped` — current speaker is STOPPED or PAUSED.
- `if_coordinator` — this speaker coordinates its group.
- `if_not_coordinator` — opposite.
- `if_queue` — queue has tracks.
- `if_no_queue` — queue empty.

```sh
soco Bedroom if_stopped : play_fav "Wake Up" : ramp_to_volume 30
```

`play_fav` only runs if Bedroom isn't already playing — avoids overriding manual playback.

## Composition rules

- Order matters: `if_*` aborts everything after it in this invocation.
- Each segment runs to completion before the next begins (synchronous).
- Long-running primitives (`wait_*`, `loop_*`, `play_file`) block the `soco` process.
- Exit code: 0 if the chain completed (or a guard short-circuited normally); non-zero if any action errored.

## Cookbook

```sh
# Auto-stop after 30 min
soco Kitchen play_fav "BBC R4" : wait 30m : stop

# Pomodoro (5 cycles, 30/30)
soco Office loop 5 : play_fav "Focus" : wait 30m : stop : wait 30m

# Auto-resume on stop, all evening
soco Bathroom loop_until 22:00 : if_stopped : play : wait 10s

# Wait for current song to end, then ungroup
soco Bedroom wait_end_track : ungroup
```
