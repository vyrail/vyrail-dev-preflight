# VYRAIL Dev Preflight

Local developer **preflight** toolkit for [VYRAIL](https://vyrail.com) contributors. Checks toolchain presence, scans a checkout for accidental secret-like filenames, and prints a Solana / Relay oriented readiness checklist. Does not contact private APIs and never uploads project files.

| | |
|---|---|
| **Project** | [VYRAIL](https://vyrail.com) |
| **GitHub org** | [github.com/vyrail](https://github.com/vyrail) |
| **Language** | Ruby 3+ and Bash |
| **Network** | Optional public RPC ping only |
| **Credentials** | None — warns if secret files are found, does not read their values by default |

## What it does

1. **Toolchain** — `node`, `npm`, `git`, optional `rustc` / `go` / `python3`
2. **Repo hygiene** — flags common secret filenames (`.env`, `*.pem`, etc.) under a path you pass
3. **Domain constants** — reminds integrators of `https://vyrail.com` and Relay Solana id `792703809`
4. **Optional** — one public Solana `getHealth` probe

## Requirements

- Ruby 3.x
- Bash (for the thin wrapper)

## Quick start

```bash
chmod +x bin/vyrail-preflight
./bin/vyrail-preflight
./bin/vyrail-preflight --path /path/to/vyrail/checkout
./bin/vyrail-preflight --rpc-ping
```

## Output

Human-readable sections with `OK` / `WARN` / `MISS` tags. Exit code `0` if no `MISS` on required tools (node/git); warnings do not fail the process unless `--strict`.

## Safety

- Does not print contents of `.env` files
- Does not require GitHub tokens
- Safe to run in CI as a non-blocking job

## License

MIT — VYRAIL ecosystem tooling.
