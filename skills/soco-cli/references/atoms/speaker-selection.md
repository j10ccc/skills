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
soco-discover -p                   # FIRST: print cached speakers (pure local read, no network)
soco-discover                      # only if -p is empty: fresh SSDP scan, writes ~/.soco-cli/
soco -l Kitchen play               # use cached list
```

**Always try `-p` before a fresh scan.** A failed `soco-discover` (returns "No speakers discovered") does not mean the cache is empty — the cache may be populated from an earlier run. In Claude Code, the sandbox blocks SSDP multicast, so the fresh scan path is unreliable anyway; the cache is your source of truth.

`-l` / `--use-local-speaker-list` is essential in cron jobs, the HTTP API server, and any one-off command — using it skips SSDP entirely, which is faster and sandbox-safe.

Cache contents at `~/.soco-cli/`:
- `speakers_v2.pickle` — speaker name → IP map
- `aliases.pickle` — interactive-shell aliases

Refresh after speaker changes:
```sh
soco-discover                     # re-run (requires SSDP — outside sandbox if running under Claude Code)
# or, from interactive shell:
rescan
```

## Discovery options (`soco-discover` flags)

Verify with `soco-discover --help`. Common flags:

- `-p` / `--print` — print cached speaker list and exit. **Use this first.** No network.
- `--subnets 192.168.10.0/24` (plural!) — restrict scan to one or more subnets (essential on multi-NIC / VLAN hosts).
- `-t N` / `--network-discovery-threads N` — parallelism for the subnet scan.
- `-n N` / `--network-discovery-timeout N` — per-device timeout in seconds.
- `-d` / `--delete-local-speaker-cache` — wipe the cache.

> Common typos that *won't* work: `--subnet` (missing `s`), `--threads`, `--show-local-speakers`. Always confirm via `--help` if unsure.

## Fuzzy match semantics

- Case-insensitive substring match.
- Multiple matches → error, lists candidates. Be more specific or use IP.
- Single match → used silently.

## Practical patterns

- **Scripting**: always pass `-l` for speed. Re-run `soco-discover` from a separate cron line nightly to refresh.
- **Multi-household**: `--subnets` per scan, or run separate `soco-discover` invocations per subnet (cache merges).
- **Wildcard ops**: prefer `_all_` over enumerating rooms (`soco _all_ stop` > `soco Kitchen stop : Lounge stop : Office stop`).
- **Coordinator-only actions**: many transport actions auto-redirect to the group coordinator. Use `if_coordinator` in chains to guard explicitly.
