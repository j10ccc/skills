# Action cheat sheet (high-frequency ~90% coverage)

Aliases in parens. soco-cli ships ~200 actions; this is the practical subset. **List every action with `soco --commands`** (top-level flag, pipe-friendly), or read `action_processor.py` upstream. Note: bare `actions` (no flag) is a **REPL-only** command inside `soco --interactive` / `soco <speaker> shell`; from the plain CLI use `--commands`.

> ⚠️ **Do not invent action names by analogy.** If an action isn't in this file, verify it exists before recommending — check `soco --commands` or [`action_processor.py`](https://github.com/avantrec/soco-cli/blob/main/soco_cli/action_processor.py). Real names are often unintuitive: "add favourite to queue" is `afq` not `qa`; "play favourite by number" is `pfn` not `pf_num`; "queue search results" is `qsr` not `qsearch`. When in doubt, ask the user to run `soco --commands | grep <keyword>` and paste the match.

## Transport

- `play` / `start` — begin playback.
- `pause`, `stop`.
- `playpause` / `pauseplay` — toggle.
- `next`, `prev` / `previous`.
- `seek HH:MM:SS` — absolute position.
- `sf <s>` / `seek_forward`, `sb <s>` / `seek_back` — relative.
- `shuffle on|off` / `sh`, `repeat on|off` / `rpt`, `play_mode <NORMAL|SHUFFLE|REPEAT_ALL|SHUFFLE_NOREPEAT>`.
- `transfer_to <speaker>` — move current playback to another speaker.
- `line_in`, `switch_to_tv` — input switching.
- `track` — print current track info.
- `playback_state` / `status` / `state` — print PLAYING/PAUSED/STOPPED/etc.
- `track_follow` / `tf` — stream track changes to stdout until killed.
- `available_actions` — which transport actions are currently legal.

## Volume / mute / balance

- `vol [N]` / `volume` / `v` — get (no arg) or set 0-100.
- `rv ±N` / `relative_volume` — delta.
- `gv [N]` / `group_volume` — group-level.
- `grv ±N` / `group_relative_volume`.
- `gve` / `group_volume_equalise` — flatten group members to same volume.
- `ramp_to_volume N` — smooth ramp; returns on completion.
- `mute on|off`, `group_mute on|off`.
- `balance ±N` — L/R balance.
- `fixed_volume on|off` — line-out fixed-volume mode.

## EQ / sub / surround

- `bass ±10`, `treble ±10` — −10..+10 range.
- `loudness on|off`.
- `night_mode on|off` / `night` (soundbars).
- `dialog_mode on|off` / `dialog` (soundbars).
- `crossfade on|off` / `fade`.
- `trueplay on|off` — speaker calibration.
- `sub_enabled on|off`, `sub_gain ±15`.
- `surround_enabled on|off`, `surround_volume_tv N`, `surround_volume_music N`.

## Queue

- `lq` / `list_queue` / `queue` / `q` — print numbered queue with current marker.
- `ql` / `queue_length`, `qp` / `queue_position`.
- `pfq N` / `play_from_queue` — play position N.
- `sqp N` / `set_queue_position` — seek queue position without starting.
- `cq` / `clear_queue`.
- `rfq N` / `remove_from_queue`, `rfq N-M` for range.
- `rctfq` / `remove_current_track_from_queue`, `rltfq` / `remove_last_track_from_queue`.
- `auq <uri>` / `add_uri_to_queue`.
- `sharelink <url>` / `add_sharelink_to_queue`, `play_sharelink <url>` — Tidal / Deezer / Apple Music share URLs.
- `save_queue <name>` / `sq` — persist queue as a Sonos playlist.

## Favourites / playlists / radio

- `lf` / `list_favourites` (US: `list_favorites`).
- `pf "<name>"` / `play_favourite`, `pfn <N>` / `play_favourite_number` — by index from `lf`.
- `cf "<name>"` / `cue_favourite`, `afq "<name>"` / `add_favourite_to_queue`.
- `lp` / `list_playlists`, `lpt "<name>"` / `list_playlist_tracks`.
- `apq "<name>"` / `add_playlist_to_queue`.
- `create_playlist <name>`, `delete_playlist <name>`.
- `llp` / `list_library_playlists`, `llpt`, `alpq` — library (SMB-share) playlists.
- `frs` / `favourite_radio_stations`, `pfrsn <N>` / `play_fav_radio_station_no`.

## Grouping / stereo pair / surround pair

- `g <speaker>` / `group` — group target into current speaker's group.
- `mg <s1> <s2> ...` / `multi_group`.
- `ug` / `ungroup`, `ungroup_all`, `ugaig` / `ungroup_all_in_group`.
- `party` / `party_mode` — join everyone into current speaker's group.
- `pause_all`, `stop_all`.
- `pair <right_speaker>` — make stereo pair, `unpair` to split.
- `add_satellites <s1> <s2>` — surround sats; `separate_satellites` to undo.
- `groups`, `groupstatus`, `zones` / `rooms` / `all_zones` / `visible_zones`.

## Music library search (requires SMB shares)

- `sl <query>` / `search_library`.
- `sart`, `salb`, `st` / `search_tracks` — narrow type.
- `albums`, `artists`, `tracks_in_album / tia`.
- `qsr N` / `queue_search_results` — queue result N from last search.
- `ls` / `last_search` — re-print results.
- `reindex`, `is_indexing`, `libraries` / `shares`.

## Alarms

See `alarms.md` for the spec format.

- `alarms` / `list_alarms`, `alarms_zone`, `alarms_spec` (copy-pasteable form).
- `add_alarm "<spec>"`, `modify_alarm <id> "<spec>"`, `copy_alarm <id>`, `move_alarm <id>`.
- `enable_alarm <id|all>`, `disable_alarm <id|all>`.
- `remove_alarm <id|all>`.
- `snooze_alarm <minutes>` — for the currently ringing alarm.

## Sleep timer

- `sleep <dur|HH:MM:SS|off>` — countdown; speaker tracks it locally.
- `sleep` (no arg) — show remaining.
- `sleep_at <HH:MM>` — schedule at clock time.

## Local files

See `local-file-playback.md`.

- `play_file <path> [_end_on_pause_]`.
- `play_m3u <path> [psri]`.
- `play_directory <dir> [psri]` — non-recursive.

Options string: `p`=print track names, `s`=shuffle, `r`=random pick, `i`=interactive (N/P/R keys).

## Speaker info

- `info` / `sysinfo` — model, IP, MAC, firmware, volume, state.
- `battery` — Move / Roam only.
- `buttons`, `mic_enabled`, `reboot_count`.
- `rename <new_name>`.
- `audio_format`, `tv_audio_delay`.

## Current-playback introspection

When the user asks "what's playing" or "where's it from":

- `track` — artist, album, title, duration, elapsed (no URI).
- `get_uri` — raw playback URI for the *current* track. **This is how you identify the source** (Apple Music vs Spotify vs local SMB vs radio). Decode the scheme / `sid=N` query param with [`sources-and-uris.md`](sources-and-uris.md).
- `shares` / `libraries` — list local SMB shares mounted on the speaker (the source pool for `x-file-cifs://` URIs).
- `playback_state` / `state` / `status` — coarse `PLAYING`/`PAUSED`/`STOPPED`.
