# Alarm CRUD & spec format

Native Sonos alarms live on the speaker — they fire even if the controller machine is off, hibernating, or offline. soco-cli is the only common CLI that exposes the full CRUD API.

## The 8-field alarm spec

```
"start_time,duration,recurrence,enabled,program,play_mode,volume,include_grouped_zones"
```

| Field | Format | Examples |
|---|---|---|
| `start_time` | `HH:MM` (24-hour, no seconds) | `07:00`, `22:30` |
| `duration` | `HH:MM` (no seconds, max 23:59) | `01:00` (1 hour), `00:30` (30 min) |
| `recurrence` | enum (see below) | `DAILY` |
| `enabled` | `True` / `False` | `True` |
| `program` | `CHIME` or favourite name | `"BBC Radio 4"` |
| `play_mode` | `NORMAL` / `SHUFFLE` / `REPEAT_ALL` / `SHUFFLE_NOREPEAT` | `SHUFFLE_NOREPEAT` |
| `volume` | 0-100 | `30` |
| `include_grouped_zones` | `True` / `False` | `False` |

> ⚠️ **Do not include seconds.** Both `start_time` and `duration` are parsed as `HH:MM` only (upstream `alarms.py` uses `strptime("%H:%M")`). Passing `07:00:00` raises `Invalid time format`. The one exception is `snooze_alarm <duration>`, which accepts `HH:MM:SS` or an integer number of minutes.

### Recurrence values

- `DAILY` — every day.
- `WEEKDAYS` — Mon-Fri.
- `WEEKENDS` — Sat-Sun.
- `ONCE` — one-shot, then disables itself.
- `ON_<bitmap>` — day digits 1-7 (1=Mon … 7=Sun). Examples:
  - `ON_135` — Mon, Wed, Fri.
  - `ON_67` — Sat, Sun (same as `WEEKENDS`).
  - `ON_1234567` — same as `DAILY`.

## Workflow: don't write specs from scratch

Print existing alarms in spec form, then edit:

```sh
soco Bedroom alarms_spec
# Bedroom: id=3 | 07:00,01:00,DAILY,True,BBC Radio 4,SHUFFLE_NOREPEAT,30,False
```

Copy the spec, edit the field(s) you want, paste back as `add_alarm`. Or use `modify_alarm` with `_` for "keep this field":

```sh
soco Bedroom modify_alarm 3 "_,_,_,_,_,_,40,_"   # only bump volume to 40
```

## Common operations

```sh
# List all alarms on a speaker
soco Bedroom alarms

# List by spec (copy-pasteable)
soco Bedroom alarms_spec

# List across all speakers
soco _all_ alarms

# Create
soco Bedroom add_alarm "07:00,01:00,DAILY,True,BBC Radio 4,SHUFFLE_NOREPEAT,30,False"

# Modify (underscore = keep)
soco Bedroom modify_alarm 3 "_,_,_,_,_,_,40,_"

# Modify all alarms with same change
soco Bedroom modify_alarms all "_,_,_,_,_,_,_,True"   # all alarms now include grouped zones

# Enable/disable without delete
soco Bedroom disable_alarm 3
soco Bedroom enable_alarm 3
soco Bedroom disable_alarms all     # disable every alarm on the speaker

# Copy an alarm to current speaker
soco Office copy_alarm 3            # copies alarm id 3 (from anywhere) onto Office
soco Office copy_modify_alarm 3 "08:00,_,_,_,_,_,_,_"  # copy + change start time

# Move (re-target)
soco Office move_alarm 3

# Snooze the currently ringing alarm
soco Bedroom snooze_alarm 9

# Delete
soco Bedroom remove_alarm 3
soco Bedroom remove_alarm all       # wipe all alarms on Bedroom
```

## Edge cases

- `program` value containing commas must be the favourite **name** as it appears in the Sonos app. `alarms_spec` quoting handles this.
- Setting `include_grouped_zones=True` means the alarm fires on whatever group the speaker is in at trigger time — useful for whole-house wake-ups if you keep the speakers grouped overnight.
- Sonos enforces a per-system alarm cap (~64). Past that, `add_alarm` errors.
- `ONCE` alarms self-disable but don't self-delete — sweep periodically with `remove_alarm` if you generate many.
