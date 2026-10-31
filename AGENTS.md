# Agent Guidelines for caddy-coraza

## Project Overview

This project builds a Docker image that packages [Caddy](https://caddyserver.com/) with the [Coraza WAF](https://coraza.io/) plugin (`coraza-caddy`). The image is published to Docker Hub as `jonathont/caddy-coraza` and is intended to be used as a drop-in WAF in front of web applications.

The build uses a two-stage Docker build:
1. `caddy:builder` — compiles Caddy with the `coraza-caddy/v2` plugin via `xcaddy`
2. `caddy:<version>` — final runtime image with the compiled binary

## Key Files

| File | Purpose |
|---|---|
| `Dockerfile` | Two-stage build; both `FROM` lines must use the same Caddy version |
| `Caddyfile` | Minimal demo config used for local testing (port 80, no TLS) |
| `coraza.conf` | Custom WAF rules loaded after OWASP CRS |
| `build_and_run.sh` | Local multi-arch build + run for smoke testing |
| `.github/workflows/docker-image.yml` | CI/CD: publishes to Docker Hub on tag push; weekly rebuild if base image differs |
| `examples/Caddyfile` | Real-world config showing WebSocket bypass and WAF snippet patterns |
| `examples/coraza.conf` | Real-world custom rules (Immich, Mastodon overrides) |
| `examples/coraza-defult-conf-override.conf` | Overrides to default CRS variables (allowed methods, body size, content types) |

## Architecture and Configuration Order

Coraza directives must be applied in this sequence within the `directives` block:

```
Include @coraza.conf-recommended         # Coraza defaults
Include /etc/caddy/coraza-override.conf  # CRS variable overrides (optional)
Include @crs-setup.conf.example          # CRS setup
Include @owasp_crs/*.conf                # OWASP Core Rule Set rules
Include /etc/caddy/coraza.conf           # Custom rules / rule suppressions
SecRuleEngine On                         # Must be last; default is DetectionOnly
```

**Critical**: `order coraza_waf first` must appear in the global Caddy block.

## Caddy Version Pinning

The Caddy version is pinned in `Dockerfile` (both `FROM` lines). Dependabot is configured to keep this updated. When bumping the version, update **both** `FROM` lines together.

## Testing

```shell
# Build and run locally (multi-arch, requires Docker buildx)
./build_and_run.sh

# Smoke tests against the running container
curl -v "http://localhost/?q=%3Cscript%3Ealert(1)%3C%2Fscript%3E"    # XSS → 403
curl -v "http://localhost/?id=1%20UNION%20SELECT%20password%20FROM%20users"  # SQLi → 403
curl -v "http://localhost/?q=select+from"                               # SQLi → 403
curl -v "http://localhost/"                                             # Clean → 200
```

There are no automated tests; validation is manual via the smoke tests above.

## Common Tasks

### Upgrading Caddy
Update both `FROM caddy:<version>-builder` and `FROM caddy:<version>` in `Dockerfile`. Dependabot handles this automatically via PRs.

### Adding a Custom Rule
Add a `SecRule` to `coraza.conf` (root, for the demo) or `examples/coraza.conf` (real-world). Use IDs starting from `1001` for custom rules; avoid IDs in the `900000`–`999999` range (reserved for CRS setup vars).

### Suppressing a False Positive
Add a `SecRule REQUEST_URI "@beginsWith /path" "id:XXXX,phase:1,pass,nolog,ctl:ruleRemoveById=RULE_ID"` to `coraza.conf`. See `examples/coraza.conf` for patterns.

### WebSocket Bypass
Coraza does not inspect WebSocket upgrades. Use the `(websocket)` snippet pattern from `examples/Caddyfile` to route WebSocket paths around the WAF before the `handle` block that imports the `(waf)` snippet.

## CI/CD

- **Tag push** (`v*`): builds and pushes to Docker Hub with semver tags + `latest`
- **Weekly schedule** (Tuesday 17:25 UTC): checks if the upstream Caddy base image has changed; only rebuilds if it has
- **`workflow_dispatch`**: manual trigger, always builds

Requires `DOCKERHUB_TOKEN` secret in the repository.

## What to Avoid

- Do not change the directive order in the `directives` block — especially do not move `SecRuleEngine On` before the rule includes.
- Do not use the same rule ID twice across `coraza.conf` and `examples/coraza.conf`.
- Do not add application-specific hostnames or credentials to `Caddyfile` or `coraza.conf` (root-level); those belong in `examples/`.
- The `build_and_run.sh` script does a multi-arch build (`linux/amd64,linux/arm64`); it does not `--push` so the image stays local. Do not add `--push` without user confirmation.
