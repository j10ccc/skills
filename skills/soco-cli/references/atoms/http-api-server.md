# HTTP API server

`soco-http-api-server` exposes the entire action vocabulary over HTTP (FastAPI + Uvicorn). Built for Home Assistant, Node-RED, Stream Deck, ESPHome buttons, NFC shortcuts, etc.

## Startup

```sh
soco-http-api-server \
  --port 8000 \
  --use-local-speaker-list \
  --macros ~/.soco-cli/macros.txt
```

Flags:
- `--port` / `-p` — default 8000.
- `--use-local-speaker-list` / `-l` — use cached discovery (almost always wanted).
- `--macros` / `-m <file>` — macro definitions, default `macros.txt` in cwd.
- `--subnets <CIDR,CIDR>` — restrict discovery.

Server listens on `0.0.0.0` and has **no authentication**. Run on a trusted LAN or front with nginx + basic auth / TLS.

Typical deployment: `systemd --user` service:

```ini
# ~/.config/systemd/user/soco-http-api.service
[Unit]
Description=soco-cli HTTP API
After=network-online.target

[Service]
ExecStart=/usr/bin/soco-http-api-server -l -p 8000 -m %h/.soco-cli/macros.txt
Restart=on-failure

[Install]
WantedBy=default.target
```

## Endpoint shapes

```
GET /                                 # banner / version
GET /speakers                         # list speaker names
GET /rediscover                       # re-run discovery
GET /list_audio_files/{dir:path}      # browse server-side audio dir

GET /{speaker}/{action}
GET /{speaker}/{action}/{arg1}
GET /{speaker}/{action}/{arg1}/{arg2}
GET /{speaker}/{action}/{arg1}/{arg2}/{arg3}

GET /macros/list
GET /macros/reload
GET /macro/{name}
GET /macro/{name}/{arg1}/.../{arg12}
```

Speaker names and args with spaces/special chars are URL-encoded by the client (FastAPI handles decoding).

## Return JSON

Action endpoints:
```json
{
  "speaker": "Kitchen",
  "action": "vol",
  "args": ["25"],
  "exit_code": 0,
  "result": "",
  "error_msg": ""
}
```

Macro endpoints:
```json
{
  "command": "Kitchen play_fav \"BBC R4\" : wait 30m : stop",
  "result": ""
}
```

`exit_code: 0` = success. Query actions (volume, status, etc.) populate `result` with stdout. Errors go to `error_msg`.

## Macro file syntax

```
# macros.txt — one definition per line
# %1..%12 = positional args from URL, _ = skip slot

partytime    = group_all : Kitchen play_fav "Party Mix" : Kitchen vol 50
quiet_house  = _all_ stop : _all_ ungroup
radio        = %1 play_fav "%2" : wait %3 : stop
doorbell     = %1 vol 50 : %1 play_file /srv/audio/doorbell.mp3 : %1 ramp_to_volume 25
```

Call:
```
GET /macro/partytime
GET /macro/radio/Kitchen/BBC%20Radio%204/30m
GET /macro/doorbell/Lounge
```

Skip an optional positional arg with `_`:
```
GET /macro/radio/Kitchen/_/30m       # uses %2's default if defined
```

`__` is a built-in passthrough macro — `GET /macro/__/Kitchen/play` ≡ `GET /Kitchen/play`. Useful for clients that only call `/macro/...`.

## Async semantics

Prefix action OR macro name with `async_` to fire-and-forget. The server `Popen`s a `soco` subprocess and returns immediately:

```
GET /async_Kitchen/track_follow        # streams events to server stderr
GET /async_macro/morning_routine
```

The PID is tracked per-key (per-speaker for actions, per-macro-name for macros). **Re-invoking the same `async_` key SIGINTs the previous process.** This makes it usable as a cancel button:

```
GET /async_Bedroom/loop_until_quiet    # starts
GET /async_Bedroom/loop_until_quiet    # second call kills the first
```

## Reload macros without restart

```
GET /macros/reload
```

Edit `macros.txt`, hit the URL, no service bounce needed. Pair with `GET /macros/list` to verify.

## Notable inspection endpoints

- `GET /speakers` — JSON list of names (use `/rediscover` first if speakers were renamed).
- `GET /macros/list` — current macro names + definitions.
- `GET /list_audio_files//srv/audio` — list playable files in a server-side dir (leading `/` after `list_audio_files/` because the path itself starts with `/`).

## Security caveats

- No auth, no TLS by default.
- The server shells out to `soco` with user-supplied args interpolated into macros. If an untrusted client can reach the port and your macros include shell metacharacters in `%N` slots, you have command injection. Keep the port LAN-only and validate inputs in macros (or front with a reverse proxy that validates).
- `play_file` via HTTP API can read **any path readable by the server process**. If the API is exposed beyond your LAN, sandbox the user account.
