# Troubleshooting

## `soco` command not found or behaves unexpectedly (edge case)

Sanity-check what's installed:

```sh
soco --version           # expected: "soco-cli x.y.z"
which -a soco
```

If `soco` is missing: install soco-cli (`pip install soco-cli` or the system package).

If `--version` reports something other than `soco-cli`: another tool may also ship a `soco` binary on this system. soco-cli and the unrelated `sonoscli` tool both ship a `sonos` binary (no `soco` collision in practice, but worth checking with `which -a` if behavior is odd).

## Slow `soco` invocations

Default discovery is SSDP-based and re-scans on every call. Fix:

```sh
soco-discover              # populate cache once
soco -l Kitchen play       # use -l (--use-local-speaker-list) everywhere afterward
```

Cache lives at `~/.soco-cli/`. Refresh after speaker changes (rename, new device, IP change).

## "Speaker not found" on multi-NIC / VLAN hosts

If SSDP can't see the speaker:

```sh
soco-discover --subnet 192.168.10.0/24
```

Or run multiple `soco-discover` invocations targeting different subnets — the cache merges.

For `play_file` reachability check: speaker must be able to connect back to the controller. See `local-file-playback.md` for the networking requirements.

## macOS: Local Network privacy prompt blocks discovery

Same as sonoscli. macOS requires explicit permission for the parent terminal process:

- Settings → Privacy & Security → Local Network → enable for **Terminal** / **iTerm** / **VS Code** / **node** (whichever runs `soco`).
- If running via Claude Code in a sandbox, the prompt may not appear — switch to `direct` mode or run `soco-discover` manually first to trigger the prompt.

## `play_file` plays but cuts out / speaker can't reach URL

The auto-picked local IP is wrong (multi-NIC) or a firewall is blocking ports 54000-54099.

```sh
# Confirm speaker's subnet
soco Kitchen info | grep -i ip

# Confirm controller has a route on that subnet
ip route                                          # Linux
route get <speaker-ip>                            # macOS

# Confirm firewall allows inbound 54000-54099 from speaker IPs
# macOS:  System Settings → Network → Firewall → Options → add `soco` binary
# Linux:  sudo ufw allow from 192.168.0.0/24 to any port 54000:54099 proto tcp
```

## Alarms set but don't fire

- Confirm `enabled=True` in the spec.
- Confirm the favourite name in field 5 exactly matches what's in the Sonos app (case-sensitive, including punctuation).
- Confirm `include_grouped_zones`: if the speaker is grouped at trigger time and this is `False`, the alarm fires silently on a non-coordinator.
- Check `recurrence` — `ONCE` self-disables after firing.

## HTTP API: macro args with spaces / quotes get mangled

URL-encode in the client: `BBC%20Radio%204` not `BBC Radio 4`. FastAPI decodes correctly; the issue is usually the curl / browser side.

Inside the macro file, quote args that contain commas or spaces:

```
radio = %1 play_fav "%2" : wait %3 : stop
```

The outer double-quotes around `%2` survive substitution.

## Command chain `:` not splitting

The separator is literally **space-colon-space** — see [`command-chaining.md`](command-chaining.md). Typical bug: `play:pause` is one broken arg; write `play : pause`.

## `soco` exits 0 but nothing happens

`if_*` guards short-circuit silently (exit 0). Example:

```sh
soco Kitchen if_stopped : play_fav "BBC R4"
```

If Kitchen is already playing, this exits 0 with no output. Add `-v` (if supported) or split the chain to debug.

## Python errors after upgrading Sonos firmware

soco-cli depends on the `soco` Python library, which occasionally lags behind Sonos firmware schema changes. Symptoms: AttributeError, KeyError on XML fields.

```sh
pip install -U soco soco-cli
# or pipx upgrade soco-cli
```

For nixpkgs: pin to a newer `soco` revision or wait for the package to update upstream.
