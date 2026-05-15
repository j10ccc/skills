# Whole-house broadcasts & announcements

> Primitives: see `../atoms/local-file-playback.md` for `play_file` mechanics and the `_end_on_pause_` trailer.

## A. "Dinner's ready" announcement

Pre-record `~/announcements/dinner.mp3`, then:
```sh
soco Kitchen group Lounge : group Office : group Bedroom : \
  Kitchen vol 40 : Kitchen play_file ~/announcements/dinner.mp3 _end_on_pause_ : \
  Kitchen ungroup_all
```

Sequence:
1. Pull all rooms into Kitchen's group.
2. Set Kitchen's group volume.
3. Stream the file (Kitchen's coordinator role broadcasts it to the group).
4. Auto-ungroup when playback ends.

## B. Doorbell chime without disturbing playing music

Lighter-weight: ramp out, chime, ramp back:
```sh
soco Kitchen vol 60 : play_file ~/sounds/chime.mp3 : wait_end_track : ramp_to_volume 25
```

For chime + restore-queue-position, accept that the current track restarts:
```sh
soco Kitchen save_queue _temp_restore : \
  play_file ~/sounds/doorbell.mp3 : wait_end_track : \
  clear_queue : add_playlist_to_queue _temp_restore : pfq 1
```

## C. Party mode (every room, same source)

```sh
soco Kitchen party_mode
soco Kitchen play_fav "Party Mix" : vol 45
```

Tear down:
```sh
soco _all_ ungroup
```

## D. Evening grouped radio via cron

```cron
0 18 * * *  user  soco -l Kitchen group Lounge : Kitchen play_fav "Jazz24" : Kitchen gv 20
```

`gv` (group_volume) sets the whole group in one call.

## E. Scheduled TTS reminder

Generate `~/announcements/today.mp3` via TTS pipeline, then:
```sh
soco Kitchen wait_until 07:30 : play_file ~/announcements/today.mp3 _end_on_pause_
```

Or wrap in cron with a pre-wait for standby wake-up:
```cron
25 7 * * *  user  soco -l Kitchen wait_until 07:30 : play_file /home/me/today.mp3 _end_on_pause_
```

## F. Whole-house "panic stop"

```sh
soco _all_ stop : _all_ ungroup
```

Or bind it as a single-keystroke alias (see `kitchen-remote.md`).
