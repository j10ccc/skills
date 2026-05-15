# Speaker selection & discovery

## Command shape

```
soco <SPEAKER> <action> [args] [: <action> [args] ...]
```

`<SPEAKER>` is either:
- A Sonos room/zone name (case-insensitive, **partial matches accepted** when unambiguous — `soco kit play` works if "Kitchen" is the only match).
- An IPv4 address (`soco 192.168.0.42 play`).
- The literal `_all_` — fans the action out to every visible speaker (`soco _all_ stop`).

## `SPKR` env var

To avoid retyping the speaker name:

```sh
export SPKR="Kitchen"
soco play              # acts on Kitchen
soco vol 25
```

Disable env lookup for a single call: `soco --no-env Lounge play`.

## Cached discovery — strongly recommended

By default each `soco` invocation does fresh SSDP discovery (slow, ~1s+). Populate the cache once, then opt in to it for fast subsequent calls:

```sh
soco-discover                      # one-time, scans LAN, writes ~/.soco-cli/
soco -l Kitchen play               # use cached list
```

`-l` / `--use-local-speaker-list` is essential in cron jobs and the HTTP API server.

Cache contents at `~/.soco-cli/`:
- `speakers.pickle` — speaker name → IP map
- `aliases.pickle` — interactive-shell aliases

Refresh after speaker changes:
```sh
soco-discover                     # re-run
# or, from interactive shell:
rescan
```

## Discovery options

- `--subnet 192.168.10.0/24` — restrict to one subnet (essential on multi-NIC / VLAN hosts).
- `--threads N` (`soco-discover`) — parallelism.
- `--show-local-speakers` (`soco-discover`) — print cache without re-scanning.

## Fuzzy match semantics

- Case-insensitive substring match.
- Multiple matches → error, lists candidates. Be more specific or use IP.
- Single match → used silently.

## Practical patterns

- **Scripting**: always pass `-l` for speed. Re-run `soco-discover` from a separate cron line nightly to refresh.
- **Multi-household**: `--subnet` per scan, or run separate `soco-discover` invocations per subnet (cache merges).
- **Wildcard ops**: prefer `_all_` over enumerating rooms (`soco _all_ stop` > `soco Kitchen stop : Lounge stop : Office stop`).
- **Coordinator-only actions**: many transport actions auto-redirect to the group coordinator. Use `if_coordinator` in chains to guard explicitly.
