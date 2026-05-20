# Coder — Self-Hosted Development Environments

## Overview

Coder provides secure, self-hosted remote development environments accessible from any device. It enables you to define standardized development environments as **templates** and provision them on demand as Docker containers (or other infrastructure).

This deployment includes a dedicated PostgreSQL database and grants Coder access to the Docker socket for provisioning workspace containers on the same host.

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                  Caddy (Reverse Proxy)                │
│  coder.home.ncronquist.com     → coder:7080           │
│  *.coder.home.ncronquist.com   → coder:7080           │
└────────────────────────┬─────────────────────────────┘
                         │
                  ┌──────▼──────┐
                  │    Coder    │
                  │  Port 7080  │
                  └──┬──────┬──┘
                     │      │
          ┌──────────▼┐   ┌▼──────────────┐
          │ PostgreSQL │   │ Docker Socket │
          │  (coder-db)│   │  (host)       │
          │  Port 5432 │   │               │
          └────────────┘   └───────┬───────┘
                                   │
                           ┌───────▼───────┐
                           │  Workspace    │
                           │  Containers   │
                           └───────────────┘
```

## Services

### coder-db (PostgreSQL)

| Property        | Value                                    |
| --------------- | ---------------------------------------- |
| Image           | `postgres:16-alpine`                     |
| Container name  | `coder-db`                               |
| Internal port   | `5432`                                   |
| Data volume     | `coder_db_data:/var/lib/postgresql/data` (named volume) |
| Network         | `coder` (internal only)                  |
| Restart policy  | `always` (survives Mac reboots)          |
| Healthcheck     | `pg_isready` every 5s, 5 retries         |

**Purpose**: Dedicated PostgreSQL instance for Coder's application data (users, templates, workspace state, audit logs). Runs on an internal network not accessible from outside the stack.

### coder

| Property        | Value                                           |
| --------------- | ----------------------------------------------- |
| Image           | `ghcr.io/coder/coder:latest`                   |
| Container name  | `coder`                                         |
| Subdomain       | `coder.home.ncronquist.com`                     |
| Wildcard        | `*.coder.home.ncronquist.com`                   |
| Internal port   | `7080`                                          |
| Config volume   | `coder_config_data:/home/coder/.config` (named) |
| Docker socket   | `/var/run/docker.sock:/var/run/docker.sock`     |
| Networks        | `proxy` (external), `coder` (internal)          |
| Restart policy  | `always` (survives Mac reboots)                 |
| Depends on      | `coder-db` (healthy)                            |

**Purpose**: The main Coder server that manages templates, workspaces, and user access. Connects to PostgreSQL for state and to the Docker socket for provisioning workspace containers.

## Storage

### PostgreSQL Data

- **Volume**: `coder_db_data` (Docker named volume)
- **Contains**: Coder's relational data (users, organizations, templates, workspace metadata, audit logs)
- **Safety**: Survives `docker compose down`. Requires explicit `docker volume rm coder_db_data` to delete.
- **Backup**:
  ```bash
  docker run --rm \
    -v coder_db_data:/data \
    -v "$(pwd)":/backup \
    alpine tar czf /backup/coder_db_$(date +%Y%m%d).tar.gz /data
  ```

### Coder Configuration

- **Volume**: `coder_config_data` (Docker named volume)
- **Contains**: Coder server configuration and state cache

### Docker Socket

- **Path**: `/var/run/docker.sock` (mounted from host)
- **Purpose**: Allows Coder to create, manage, and destroy workspace containers on the host
- **Security note**: Docker socket access grants root-equivalent permissions on the host. Only trusted users should have access to the Coder instance.

## Networking

### proxy (external)

Shared with the Caddy reverse proxy. The Coder server is accessible via this network at `coder.home.ncronquist.com`.

### coder (internal)

Internal network connecting Coder to its PostgreSQL database. Not accessible from outside the stack.

### Wildcard Subdomain

Coder uses wildcard subdomains (`*.coder.home.ncronquist.com`) for workspace-specific features like port forwarding and web terminal access. Ensure your DNS and Caddy configuration support wildcard routing.

### Caddy Configuration

Add the following to your Caddy configuration (already present in `apps/caddy/Caddyfile`):

```caddy
# In the *.home.ncronquist.com block:
@coder host coder.home.ncronquist.com
handle @coder {
    reverse_proxy coder:7080 {
        header_up Host              {upstream_hostport}
        header_up X-Real-IP        {remote_host}
        header_up X-Forwarded-For  {remote_host}
        header_up X-Forwarded-Proto {scheme}
        # WebSocket upgrade passthrough
        header_up Upgrade    {http.request.header.Upgrade}
        header_up Connection {http.request.header.Connection}
        # Disable buffering — required for WebSocket and streaming responses
        flush_interval -1
    }
}

# Separate block for Coder workspace wildcard:
*.coder.home.ncronquist.com {
    tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    }
    reverse_proxy coder:7080 {
        header_up Host              {upstream_hostport}
        header_up X-Real-IP        {remote_host}
        header_up X-Forwarded-For  {remote_host}
        header_up X-Forwarded-Proto {scheme}
        header_up Upgrade    {http.request.header.Upgrade}
        header_up Connection {http.request.header.Connection}
        flush_interval -1
    }
}
```

> The `*.coder.home.ncronquist.com` block requires a separate TLS certificate
> since a wildcard cert only covers one subdomain level. Caddy obtains it
> automatically via the same Cloudflare DNS-01 challenge.

## Environment Variables

| Variable                      | Value / Source                                | Description                                |
| ----------------------------- | -------------------------------------------- | ------------------------------------------ |
| `POSTGRES_USER`               | `coder`                                      | PostgreSQL username                        |
| `POSTGRES_PASSWORD`           | `${CODER_DB_PASSWORD}` (from `.env`)         | PostgreSQL password                        |
| `POSTGRES_DB`                 | `coder`                                      | PostgreSQL database name                   |
| `CODER_PG_CONNECTION_URL`     | `postgresql://coder:...@coder-db:5432/coder` | Full connection string for Coder → Postgres|
| `CODER_ACCESS_URL`            | `https://coder.home.ncronquist.com`          | Public URL for the Coder dashboard          |
| `CODER_WILDCARD_ACCESS_URL`   | `*.coder.home.ncronquist.com`                | Wildcard URL for workspace features         |

## Initial Setup

1. Copy `.env.example` to `.env` and set a strong `CODER_DB_PASSWORD`
2. Start the stack: `docker compose up -d`
3. Navigate to `https://coder.home.ncronquist.com`
4. Create your admin account on first access
5. Create a template (e.g., Docker-based dev environment)
6. Launch your first workspace from the template

## Templates

Coder uses **templates** to define reproducible development environments. Templates are written in Terraform and can specify:

- Base Docker image (e.g., `ubuntu:22.04`, custom images with your toolchain)
- Resource limits (CPU, memory)
- Persistent volumes for project data
- Pre-installed tools and extensions
- Git configuration and dotfiles

Start with the built-in Docker template and customize from there.

## Backup Considerations

- **PostgreSQL data**: Back up `./data/coder-db/` — contains all Coder application state
- **Coder config**: Back up `./data/coder/` — contains server configuration
- **Templates**: Store templates in a Git repository (e.g., in your Gitea instance) for version control
- **Workspace data**: Workspace containers are ephemeral by default; use persistent volumes in templates for data that should survive rebuilds
