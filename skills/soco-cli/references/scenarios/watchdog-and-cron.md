# Watchdog loops & cron schedules

> Primitives: see `../atoms/command-chaining.md` for `loop`/`loop_until`/`if_*`, `../atoms/speaker-selection.md` for `-l` caching and `_all_`.

## A. Auto-resume — "if anyone hits stop, restart in 10s"

```sh
soco Bathroom loop : if_stopped : play : wait 10s
```

Bound to working hours:
```sh
soco Bathroom loop_until 22:00 : if_stopped : play : wait 10s
```

Run under `systemd --user` with `Restart=on-failure` for resilience.

## B. Hourly station rotation

```sh
soco Lounge loop : play_fav "Jazz24" : wait 1h : play_fav "Classical FM" : wait 1h : play_fav "BBC R6" : wait 1h
```

## C. Pomodoro — 30 min work / 30 min rest, 5 cycles

```sh
soco Office loop 5 : play_fav "Focus" : wait 30m : stop : wait 30m
```

## D. Cron quiet hours

```cron
# Drop volume across the house at 22:00, raise at 08:00
0 22 * * *  user  soco -l _all_ ramp_to_volume 12
0  8 * * *  user  soco -l _all_ ramp_to_volume 25

# Stop everything at midnight
0  0 * * *  user  soco -l _all_ stop : _all_ ungroup
```

## E. Sweep idle speakers — ungroup if stopped >15 min

```cron
*/30 * * * *  user  soco -l _all_ wait_stopped_for 15m : ungroup
```

`wait_stopped_for` returns immediately if the threshold is already met — cheap to run every 30 min.

## F. Conditional cron — clean up only if nothing's playing

```cron
30 23 * * *  user  soco -l Kitchen if_stopped : pause_all : ungroup_all
```

`if_stopped` short-circuits the chain — nightly cleanup runs only when no one's actively listening.

## G. Weekend-only scheduled session

```cron
0 10 * * 6,0  user  soco -l Lounge play_fav "Weekend Brunch" : gv 30 : wait 2h : stop
```
