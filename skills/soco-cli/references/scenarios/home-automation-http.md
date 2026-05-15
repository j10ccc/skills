# Home Assistant / curl-driven control

> Primitives: see `../atoms/http-api-server.md` for full endpoint / macro / async semantics.

## A. Deploy via systemd

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

```sh
systemctl --user enable --now soco-http-api.service
```

## B. Useful macros for home automation

```
# ~/.soco-cli/macros.txt
partytime    = group_all : Kitchen play_fav "Party Mix" : Kitchen vol 50
quiet_house  = _all_ stop : _all_ ungroup
radio        = %1 play_fav "%2" : wait %3 : stop
doorbell     = %1 vol 50 : %1 play_file /srv/audio/doorbell.mp3 : %1 ramp_to_volume 25
goodnight    = _all_ ramp_to_volume 10 : wait 15m : _all_ stop
arrive_home  = Kitchen play_fav "Welcome" : Kitchen vol 25 : Lounge group Kitchen
leave_home   = _all_ stop : _all_ ungroup : Kitchen disable_alarm 3
```

## C. Home Assistant REST commands

```yaml
# configuration.yaml
rest_command:
  sonos_macro:
    url: "http://hassbox.local:8000/macro/{{ name }}"
    method: GET
  sonos_action:
    url: "http://hassbox.local:8000/{{ speaker }}/{{ action }}/{{ arg | urlencode }}"
    method: GET

# automation
automation:
  - alias: "Doorbell rings"
    trigger:
      platform: state
      entity_id: binary_sensor.front_door
      to: "on"
    action:
      service: rest_command.sonos_macro
      data:
        name: "doorbell/Lounge"

  - alias: "Bedtime button pressed"
    trigger:
      platform: state
      entity_id: input_button.bedtime
    action:
      service: rest_command.sonos_macro
      data:
        name: "goodnight"
```

## D. Presence-based switching (with async cancel)

Imagine an HA automation that starts background music when you enter a room and stops it when you leave. Use `async_` so the macro can be cancelled by simply calling the same key:

```
# macros.txt
async_office_music = Office play_fav "Focus" : loop_until 18:00 : if_stopped : play : wait 10s
```

```yaml
# HA
- alias: "Enter office"
  trigger: { platform: state, entity_id: binary_sensor.office_presence, to: "on" }
  action:
    service: rest_command.sonos_macro
    data: { name: "async_office_music" }

- alias: "Leave office"
  trigger: { platform: state, entity_id: binary_sensor.office_presence, to: "off" }
  action:
    service: rest_command.sonos_action
    data: { speaker: "Office", action: "stop", arg: "" }
```

Re-triggering `async_office_music` SIGINTs the previous loop, so re-entries are safe.

## E. Stream Deck buttons via curl

Stream Deck "System → Website" buttons or a tiny shell script:
```sh
#!/bin/sh
# ~/bin/soco-deck
curl -sf "http://hassbox.local:8000/macro/$1${2:+/$2}${3:+/$3}" | jq -r .result
```

Bind buttons to `soco-deck partytime`, `soco-deck quiet_house`, `soco-deck radio Kitchen "BBC R4" 30m`.

## F. Verify deploy

```sh
curl -s http://hassbox.local:8000/speakers | jq
curl -s http://hassbox.local:8000/macros/list | jq
curl -s http://hassbox.local:8000/Kitchen/info | jq
```

Reload after editing macros:
```sh
curl http://hassbox.local:8000/macros/reload
```

## Security reminder

LAN-only by default. Full caveats + nginx fronting recipe live in [`../atoms/http-api-server.md`](../atoms/http-api-server.md) ("Security caveats" section).
