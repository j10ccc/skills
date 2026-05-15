# Bedtime & timed radio

> Primitives: see `../atoms/command-chaining.md` for the `:` DSL, `../atoms/actions-cheatsheet.md` for `sleep` / `ramp_to_volume`.

## A. "Play BBC Radio 4 for 30 minutes while I cook, then stop"

```sh
soco Kitchen play_fav "BBC Radio 4" : wait 30m : stop
```

Don't stomp on existing playback:
```sh
soco Kitchen if_stopped : play_fav "BBC Radio 4" : wait 30m : stop
```

## B. "Stop when this episode ends"

```sh
soco Bedroom wait_end_track : stop
```

`wait_end_track` blocks on the "track ended" UPnP event — survives pauses.

## C. "Stop everything if the house has been quiet for 5 min"

Cron-friendly sweep:
```sh
soco Kitchen wait_stopped_for 5m : stop_all
```

Use `wsfnp` if a pause should count as "still in use":
```sh
soco Kitchen wait_stopped_for_not_pause 5m : stop_all
```

## D. Native Sonos sleep timer

The speaker tracks the timer itself, so the controller can drop off:

```sh
soco Bedroom sleep 30m       # countdown
soco Bedroom sleep_at 23:30  # clock time
soco Bedroom sleep off       # cancel
soco Bedroom sleep           # show remaining
```

## E. Fade volume as I fall asleep

Stepwise:
```sh
soco Bedroom vol 30 : wait 10m : vol 20 : wait 10m : vol 10 : wait 10m : stop
```

Smooth (ramp returns when complete):
```sh
soco Bedroom ramp_to_volume 10 : wait 20m : stop
```

## F. Event-driven daemon — wake on play, sleep on stop

Run under `systemd --user` or `tmux`:

```sh
# adjust volume the moment someone starts streaming
soco Office wait_start : vol 25

# ungroup the moment playback stops
soco Office wait_stop : ungroup
```
