# Adding a New Service — Runbook

Guide for adding a new Docker service to the homelab.

## Step 1: Create Service Directory

```bash
mkdir -p docker/apps/<service-name>
```

## Step 2: Create SPEC.md

Document the service specification:

```markdown
# <Service Name> — Specification

## Overview
What the service does and why we're running it.

## Configuration
| Item | Value |
|---|---|
| Image | `<docker-image>` |
| Subdomain | `<name>.home.ncronquist.com` |
| Port | `<internal-port>` |
| Network | `proxy` |

## Environment Variables
...

## Data / Volumes
...
```

## Step 3: Create compose.yml

```yaml
services:
  <service-name>:
    image: <docker-image>:latest
    container_name: <service-name>
    restart: unless-stopped
    environment:
      - TZ=${TZ:-America/Los_Angeles}
    volumes:
      - ./data/<service-name>:/config
    networks:
      - proxy

networks:
  proxy:
    external: true
```

## Step 4: Create .env.example

```bash
# <Service Name>
# List any required environment variables here.
```

## Step 5: Add to Root docker-compose.yml

Edit `docker/docker-compose.yml` and add:

```yaml
include:
  # ... existing includes ...
  - path: ./apps/<service-name>/compose.yml
```

## Step 6: Add Caddy Reverse Proxy Entry

Edit `docker/apps/caddy/Caddyfile` and add within the `*.home.ncronquist.com` block:

```caddy
@<service-name> host <name>.home.ncronquist.com
handle @<service-name> {
    reverse_proxy <service-name>:<port>
}
```

Then reload Caddy:

```bash
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
```

## Step 7: Add DNS Rewrite (if needed)

If the service uses a different subdomain pattern, add a DNS Rewrite in AdGuard Home. The wildcard `*.home.ncronquist.com` should cover most cases automatically.

## Step 8: Create Data Directory

```bash
mkdir -p docker/apps/<service-name>/data/<service-name>
```

## Step 9: Test

```bash
# Validate compose
docker compose config

# Start the new service
docker compose up -d <service-name>

# Verify it's accessible
curl -I https://<name>.home.ncronquist.com
```

## Step 10: Commit

```bash
git add docker/apps/<service-name>/
git add docker/docker-compose.yml
git add docker/apps/caddy/Caddyfile
git commit -m "Add <service-name> service"
```
