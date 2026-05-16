# Troubleshooting

## `soco` command not found or behaves unexpectedly (edge case)

Sanity-check what's installed:

```sh
soco --version           # expected: "soco-cli x.y.z"
which -a soco
```

If `soco` is missing: install soco-cli (`pip install soco-cli` or the system package).

If `--version` reports something other than `soco-cli`: another tool may also ship a `soco` binary on this system. soco-cli and the unrelated `sonoscli` tool both ship a `sonos` binary (no `soco` collision in practice, but worth checking with `which -a` if behavior is odd).

## Discovery & connectivity

### Always start with the cache

`soco-discover -p` is a local pickle read — sandbox-safe, zero network. If it lists speakers, use them via `soco -l <name> <action>` and **stop debugging discovery**. Everything below this section is irrelevant when the cache is already populated.

### Populating an empty cache

`soco-discover` does a fresh SSDP scan. It's flaky — SSDP multicast routinely drops packets. **If the first call returns "No speakers discovered" but you're confident the speakers are online, retry up to 5 times before concluding the scan has failed structurally:**

```sh
for i in 1 2 3 4 5; do soco-discover && break; done
```

If 5 retries all fail, the cause is structural — see the table below.

### Common causes of a failed scan

| Cause | Symptom | Fix |
|---|---|---|
| **Claude Code sandbox** (most likely under Claude Code) | Silent "No speakers discovered", no error | Bypass: `dangerouslyDisableSandbox: true`. See sandbox details below. |
| **Multi-NIC / VLAN host** | Scan went out the wrong interface | `soco-discover --subnets 192.168.10.0/24` (plural!). Multiple invocations cache-merge. |
| **macOS Local Network privacy** | Parent terminal lacks the entitlement | Settings → Privacy & Security → Local Network → enable for **Terminal** / **iTerm** / **VS Code** / **node**. |
| **Speaker actually offline** | Sonos app also can't see it | Power-cycle the speaker. |

### Once you have a cache: always pass `-l`

Every `soco` invocation without `-l` does a fresh SSDP rescan (~1s slower per call, and sandbox-prone). Pass `-l` everywhere — one-offs, cron, scripts, HTTP server. Refresh the cache after rename / new device / IP change.

### Claude Code sandbox specifics

Under the default Bash sandbox, two distinct blocks bite:

| Operation | Why it fails | Symptom |
|---|---|---|
| `soco-discover` (no `-p`) | SSDP multicast to 239.255.255.250:1900 | Silent: "No speakers discovered" with no sandbox error |
| `soco <speaker> <action>` (any form, with or without `-l`) | TCP to speaker LAN IP `:1400` | Explicit: `Operation not permitted` from urllib3 |

**Sandbox-safe**: `soco-discover -p`, `soco --version`, `soco --commands`, `soco --help`.

**Everything else**: run with `dangerouslyDisableSandbox: true`. Alternative: persistent allowlist via `/sandbox` (LAN subnet + SSDP), but the per-call bypass is the simpler default.

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
