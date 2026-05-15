# One-key kitchen / bathroom remote

> Primitives: see `../atoms/interactive-shell.md` for REPL, aliases, and single-keystroke mode.

Turn an old laptop, a Raspberry Pi with a USB keyboard, or a `tmux` pane into a single-keystroke Sonos remote.

## A. Build the alias set

```sh
soco Kitchen     # open REPL with Kitchen pre-selected
```

Define one-character aliases:
```
alias p play
alias s stop
alias n next
alias b prev
alias + rv 5
alias - rv -5
alias 1 play_fav "BBC Radio 4"
alias 2 play_fav "Jazz24"
alias 3 play_fav "Classical FM"
alias q stop_all
alias g group Lounge
alias u ungroup
save_aliases
```

## B. Enter single-keystroke mode

```
sk
```

Now each typed character invokes the matching alias immediately, no Enter:
- `p` plays, `s` stops
- `+` / `-` adjust volume
- `1`/`2`/`3` switch radio stations
- `q` panic-stops the whole house

Press Esc to leave SK mode.

Or start in SK from the OS shell:
```sh
soco --sk Kitchen
```

## C. Multi-arg aliases (regular REPL only)

```
alias r play_fav "%1" : wait 30m : stop
alias morning vol %1 : play_fav "%2"

r "BBC R4"
morning 20 "Wake Up Mix"
```

Can't be used in SK mode (no way to type args).

## D. Cross-room recipes via `push` / `pop`

```
alias announce push : set Kitchen : play_file /srv/dinner.mp3 : pop
```

## E. Deployment ideas

- **Raspberry Pi Zero + USB numpad** on the kitchen counter, autorunning `soco --sk Kitchen` in a console login.
- **Pinned `tmux` pane** on the workstation for quick volume tweaks without app-switching.
- **Stream Deck** sending keystrokes to a focused terminal running the REPL (or use HTTP API instead — see `scenarios/home-automation-http.md`).
- **Custom NFC tags** that SSH into the controller and send keystrokes via Tasker / Shortcuts.

For setups without a keyboard, prefer the HTTP API server.
