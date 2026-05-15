# Local file playback

Sonos speakers can only stream from URLs. soco-cli works around this by spinning up an HTTP server on the controller machine and feeding the speaker a URL pointing back at it.

## Commands

```sh
soco Kitchen play_file ~/Music/track.mp3
soco Kitchen play_file ~/announcements/dinner.mp3 _end_on_pause_
soco Kitchen play_directory ~/Music/Aphex psri
soco Kitchen play_m3u ~/Playlists/morning.m3u psri
```

## What happens under the hood

1. Pick a local IP reachable from the speaker's subnet (probed via `ifaddr` + a test connection to `<speaker>:1400/status/info`).
2. Start a `ThreadedHTTPServer` (Python stdlib) on the first free port in **54000-54099**.
3. Mount a `RangeRequestHandler` — **byte-range requests are supported**, which is what lets Sonos seek and buffer reliably.
4. Hardening: handler 403s any path that isn't the served file, and any client IP not in the speaker's `all_zones` list.
5. Call `speaker.play_uri("http://<local-ip>:<port>/<urlencoded-filename>")`.
6. Subscribe to `avTransport` UPnP events.
7. Tear down the HTTP server when the speaker stops (default) or stops/pauses (with `_end_on_pause_`).

The `soco` process blocks for the duration. Backgrounding to run multiple `play_file` calls in parallel is possible but each uses a different port.

## Supported audio formats

`SUPPORTED_TYPES` in upstream: **MP3, M4A, MP4, FLAC, OGG, WMA, WAV, AIFF**.

**No transcoding** — the speaker plays whatever bytes you serve, so the file must already be in a codec Sonos natively supports. Convert with `ffmpeg` ahead of time if needed.

## The `_end_on_pause_` trailer

Without it, `play_file` only tears down on STOPPED. Pause keeps the HTTP server alive (resume works seamlessly). With `_end_on_pause_`, pause also terminates — useful for announcements where you don't want a paused state to leave a dangling server:

```sh
soco Kitchen play_file ~/announcements/dinner.mp3 _end_on_pause_
```

## `play_directory` semantics

- **Non-recursive** — only files directly in the directory, sorted alphabetically.
- Filters to supported audio extensions.
- Plays sequentially, one `play_uri` per file.
- Options string `psri`:
  - `p` — print each track name before playing.
  - `s` — shuffle.
  - `r` — pick one random file (just one).
  - `i` — interactive: while playing, press `N` + Enter for next, `P` for previous, `R` to resume.

## `play_m3u` semantics

- Accepts `.m3u` (no header required) or `.m3u8` (requires `#EXTM3U` first line).
- Resolves relative paths against the M3U's directory.
- Same `psri` options.
- Streams are played one at a time (no gapless).

## Networking requirements

- **Same broadcast domain**: controller IP must be directly reachable from the speaker. Across VLANs, ensure the controller has a NIC in the speaker's subnet, or set up a routing/firewall rule.
- **Inbound 54000-54099**: firewall must allow the speaker to reach the controller on these ports.
- **No NAT translation** between controller and speaker — Sonos uses the literal URL the CLI tells it.

Confirm reachability:
```sh
soco Kitchen info | grep -i ip       # see speaker IP
ip route get <speaker-ip>             # see which local NIC reaches it
```

## When NOT to use

- **Library at scale**: if you have a real music library, mount it as an SMB share and let Sonos index it (`reindex` + `sl`/`salb`/`st` actions). `play_directory` is for occasional ad-hoc playback.
- **Cross-network playback**: serve files from a server on the same subnet as the speaker instead, and use `add_uri_to_queue` / `play_uri` directly.
- **Long-running playlists**: each `play_m3u` track is a fresh `play_uri` call, so any controller-side hiccup (Ctrl-C, machine sleep) ends playback.
