# Decoding a track URI / identifying the source

`get_uri` (and the URIs returned by `track`, `lq`, etc.) reveal where a Sonos speaker is pulling audio from. The **scheme** + the `sid=N` query parameter identify the source service.

## Workflow

```sh
soco -l Bedroom get_uri
# → x-soco-http:song%3a300117761.mp4?sid=204&flags=8232&sn=2
```

1. Inspect the **scheme** (before the colon).
2. If the scheme is `x-soco-http:` (the generic music-service envelope), inspect the **`sid=N`** query param to identify the service.
3. `sn=N` (when present) is the account-slot number — useful when the user has multiple logins of the same service linked.

## URI scheme → source

| URI prefix / param | Source |
|---|---|
| `x-file-cifs://…` | Local SMB library share (see `shares` action) |
| `x-rincon-mp3radio://…` | MP3 internet radio stream |
| `x-sonosapi-stream:…` | Sonos-curated radio / TuneIn |
| `x-sonosapi-hls:…` | HLS stream (BBC Sounds, etc.) |
| `x-sonosapi-hls-static:…` | Static HLS (some podcasts) |
| `x-soco-http:…?sid=9` | Spotify |
| `x-soco-http:…?sid=160` | Amazon Music |
| `x-soco-http:…?sid=174` | Tidal |
| `x-soco-http:…?sid=204` | Apple Music |
| `x-soco-http:…?sid=254` | YouTube Music |
| `x-soco-vli:…` | AirPlay 2 input |
| `x-rincon-stream:…` | Line-In input (analog) |
| `x-soco-htastream:…` | Soundbar TV input (HDMI ARC / optical) |
| `x-rincon-queue:…` | Speaker's own queue marker (not a source itself — points into the queue) |
| `x-rincon-cpcontainer:…` | Music-service container / playlist URI |

## Limits & caveats

- The `sid` list above covers the major services as of 2026. New services or regional Sonos partners may have other sids — for the authoritative list query the speaker's `MusicServices` UPnP service or check upstream sonos-svrooij docs (see [Official documentation table in SKILL.md](../SKILL.md#official-documentation)).
- `sn=N` (account slot) is not directly mappable from the CLI; the user has to look at the Sonos app under Settings → Services to see which slot is which login.
- For `x-file-cifs://` URIs, the host portion is the SMB share path — run `soco <speaker> shares` to list mounted shares the speaker can read.
- soco-cli does **not** have a built-in source decoder action. This table is the lookup you do mentally (or via `grep`) when the user asks "where's it from".

## Related actions

- `track` — track metadata (no URI).
- `get_uri` — raw URI (this table is how you read its output).
- `sharelink <url>` — opposite direction: take a share URL from Spotify / Tidal / etc. and enqueue it on the speaker.
- `shares` / `libraries` — list mounted SMB sources (for `x-file-cifs://` URIs).
