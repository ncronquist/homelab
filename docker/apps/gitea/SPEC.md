# Gitea — Self-Hosted Git Server

## Overview

Gitea is a lightweight, self-hosted Git service with a clean web UI. It provides repository hosting, issue tracking, pull requests, and CI/CD capabilities — all in a single, low-resource binary.

This deployment uses SQLite as the database backend, requiring no external database container and simplifying backups to a single data directory.

## Architecture

```
┌──────────────────────────────────────────────┐
│              Caddy (Reverse Proxy)            │
│  git.home.ncronquist.com → gitea:3000         │
└──────────────────────┬───────────────────────┘
                       │ HTTP
                ┌──────▼──────┐
                │    Gitea    │
    SSH ────────▶   Port 22   │
  (host:2222)   │  Port 3000  │
                └──────┬──────┘
                       │
                ┌──────▼──────┐
                │   SQLite    │
                │  (embedded) │
                └─────────────┘
```

## Service

| Property        | Value                                           |
| --------------- | ----------------------------------------------- |
| Image           | `gitea/gitea:latest`                            |
| Container name  | `gitea`                                         |
| Subdomain       | `git.home.ncronquist.com`                       |
| Internal ports  | `3000` (HTTP/web UI), `22` (SSH)                |
| Host ports      | `2222:22` (SSH only; HTTP is proxied via Caddy)  |
| Config volume   | `gitea_data:/data` (Docker named volume)        |
| Network         | `proxy` (external, shared with Caddy)           |
| Database        | SQLite (embedded, no external DB required)       |
| Restart policy  | `always` (survives Mac reboots)                 |

## Storage

### Data Directory

- **Volume**: `gitea_data` (Docker named volume, managed by Docker)
- **Contains**: Git repositories, SQLite database, Gitea configuration, avatars, attachments, and LFS objects
- **Safety**: Named volumes survive `docker compose down` without the `-v` flag. The volume must be explicitly deleted with `docker volume rm gitea_data`.
- **Backup**:
  ```bash
  docker run --rm \
    -v gitea_data:/data \
    -v "$(pwd)":/backup \
    alpine tar czf /backup/gitea_data_$(date +%Y%m%d).tar.gz /data
  ```
- **Restore**:
  ```bash
  docker run --rm \
    -v gitea_data:/data \
    -v "$(pwd)":/backup \
    alpine tar xzf /backup/gitea_data_<date>.tar.gz -C /
  ```

## Networking

### HTTP (Web UI)

The web UI on port `3000` is proxied through Caddy on the `proxy` network. No HTTP port is exposed directly to the host.

### SSH

SSH is exposed on host port `2222` to avoid conflicts with the host's own SSH daemon on port `22`. Configure your Git SSH remotes accordingly:

```bash
# Clone via SSH
git clone ssh://git@<host-ip>:2222/username/repo.git

# Or configure ~/.ssh/config
Host gitea
    HostName <host-ip>
    Port 2222
    User git
```

### Caddy Configuration

Add the following to your Caddy configuration:

```
git.home.ncronquist.com {
    reverse_proxy gitea:3000
}
```

## Environment Variables

| Variable                      | Value                               | Description                          |
| ----------------------------- | ----------------------------------- | ------------------------------------ |
| `USER_UID`                    | `501`                               | User ID for file permissions         |
| `USER_GID`                    | `20`                                | Group ID for file permissions        |
| `GITEA__database__DB_TYPE`    | `sqlite3`                           | Use embedded SQLite database         |
| `GITEA__server__DOMAIN`       | `git.home.ncronquist.com`           | Public-facing domain name            |
| `GITEA__server__ROOT_URL`     | `https://git.home.ncronquist.com`   | Full public URL (used in links/emails)|

Gitea supports extensive configuration via environment variables using the `GITEA__section__KEY` format. See the [Gitea documentation](https://docs.gitea.com/administration/config-cheat-sheet) for all available options.

## Initial Setup

1. Start the container: `docker compose up -d`
2. Navigate to `https://git.home.ncronquist.com`
3. Complete the web-based installation wizard:
   - Database: SQLite3 (pre-configured via environment variable)
   - Site title, admin account, and other settings
4. Create your first repository

## Optional: Gitea Actions (CI/CD)

Gitea includes a built-in CI/CD system compatible with GitHub Actions workflows. To enable it later:

1. Add `GITEA__actions__ENABLED=true` to the environment variables
2. Deploy a Gitea Actions runner container alongside Gitea
3. Register the runner with your Gitea instance

This is not enabled by default to keep the initial deployment simple.

## Backup Considerations

- **All data**: Back up `./data/gitea/` — contains repositories, database, config, and all attachments
- **Simple restore**: Copy the data directory to a new host and start the container
- Gitea also provides a built-in `gitea dump` command for creating portable backups
